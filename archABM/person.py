import logging

from simpy import Environment, Interrupt, Process, Timeout

from .database import Database
from .place import Place
from .event import Event
from .event_generator import EventGenerator
from .event_model import EventModel
from .parameters import Parameters
from .snapshot_person import SnapshotPerson


class Person:
    """Person primitive"""

    id = -1

    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.next()
        self.id = Person.id

        self.env = env
        self.db = db
        self.params = params

        self.generator = EventGenerator(env, db)
        self.current_process = None
        self.place = None
        self.event = None
        self.model = None
        self.duration = None

        self.status = 0  # 0: susceptible, 1: infective

        self.CO2_level = self.db.model.params.CO2_background
        self.quanta_inhaled = 0.0

        self.elapsed = 0.0
        self.last_updated = 0

        self.snapshot = SnapshotPerson()

    @classmethod
    def reset(cls) -> None:
        """Resets :class:`~archABM.person.Person` ID."""
        Person.id = -1

    @staticmethod
    def next() -> None:
        """Increments one unit the :class:`~archABM.person.Person` ID."""
        Person.id += 1

    def start(self) -> None:
        """Initiates the event queue processing"""
        logging.info("[%.2f] Person %d starting up" % (self.env.now, self.id))
        self.env.process(self.process())

    def process(self) -> None:
        """Processes the chain of discrete events

        The person is moved from the current :class:`~archABM.place.Place` to the new one based on the generated :class:`~archABM.event.Event`, 
        and stays there for a defined duration (in minutes).

        Once an event or task get fulfilled, the :class:`~archABM.event_generator.EventGenerator` produces a new :class:`~archABM.event.Event`.
        If, after a limited number of trials, the :class:`~archABM.event_generator.EventGenerator` is not able to correctly generate an event,
        a random one is created.

        If a person gets interrupted while carrying out (waiting) its current task, the assigned event happens to be the new one. 

        .. note::
            State snapshots are taken after each event if fulfilled.

        Yields:
            Process: an event yielding generator
        """
        cont_event = 0
        cont_event_max = 1000  # TODO: review maximum allowed number of events per person
        while True:
            # generate event
            cont_generator = 0
            cont_generator_max = 3
            while self.event is None:  # TODO: review maximum allowed number of events per person
                self.event = self.generator.generate(self.env.now, self)
                cont_generator += 1
                # if exceeded, generate random event
                if cont_generator > cont_generator_max:
                    duration = self.model.duration(self.env.now)
                    self.event = Event(self.model, self.place, duration)
                    break
            self.model = self.event.model
            self.duration = self.event.duration
            activity = self.model.params.activity

            # TODO: review if we want to save only new places or all of them => self.place != self.event.place and not self.event.place.full()
            # move from current place to new one
            if self.event is not None and self.event.place is not None:

                if self.place != self.event.place and not self.event.place.full():
                    # remove from current place
                    if self.place is not None:
                        self.place.remove_person(self)

                    # add to new place
                    self.place = self.event.place
                    self.place.add_person(self)
                else:
                    self.place.update_place()

                # save snapshot (if first event or elapsed time > 0)
                elapsed = self.env.now - self.last_updated
                if elapsed > 0 or cont_event == 0:
                    self.save_snapshot()
                    pass

                logging.info("[%.2f] Person %d event %s at place %s for %d minutes" % (
                    self.env.now, self.id, self.model.params.activity, self.place.params.name, self.duration,))

            self.event = None
            self.last_updated = self.env.now
            self.current_process = self.env.process(self.wait())
            yield self.current_process

            cont_event += 1
            if cont_event > cont_event_max:
                break

    def wait(self) -> None:
        """Wait for a certain amount of time

        Yields:
            Timeout: event triggered after a delay has passed 
        """
        try:
            yield self.env.timeout(self.duration)
        except Interrupt:
            # print("interrupted")
            pass

    def assign_event(self, event: Event) -> None:
        """Interrupt current task and assign new event

        Args:
            event (Event): new assigned event
        """
        if self.current_process is not None and not self.current_process.triggered:
            self.current_process.interrupt("Need to go!")
            logging.info("[%.2f] Person %d interrupted current event" % (self.env.now, self.id))
        self.event = event
        self.generator.consume_activity(event.model)

    # TODO: review if we need to update the risk of infected people as well
    # TODO: review infection risk metric: average vs cumulative
    def update(self, elapsed: float, quanta_inhaled: float, CO2_level: float) -> None:
        """Update the infection risk probability and the CO\ :sub:`2` concentration (ppm).

        Args:
            elapsed (float): event elapsed time (in minutes)
            infection_risk (float): infection risk probability 
            CO2_level (float): CO\ :sub:`2` concentration (ppm) 
        """
        # self.elapsed += elapsed
        # self.infection_risk_avg += elapsed * (infection_risk - self.infection_risk_avg) / self.elapsed
        # self.infection_risk_cum += infection_risk
        # self.CO2_level += elapsed * (CO2_level - self.CO2_level) / self.elapsed

        self.CO2_level = CO2_level
        self.quanta_inhaled += quanta_inhaled

    def save_snapshot(self) -> None:
        """Saves state snapshot on :class:`~archABM.snapshot_person.SnapshotPerson`"""
        self.snapshot.set("run", self.db.run)
        self.snapshot.set("time", self.env.now, 0)
        self.snapshot.set("person", self.id)
        self.snapshot.set("status", self.status)
        self.snapshot.set("place", self.place.id)
        self.snapshot.set("event", self.model.id)
        self.snapshot.set("CO2_level", self.CO2_level, 2)
        self.snapshot.set("quanta_inhaled", self.quanta_inhaled, 6)
        self.db.results.write_person(self.snapshot)

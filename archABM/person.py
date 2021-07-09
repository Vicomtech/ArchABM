import logging

from simpy import Environment, Interrupt

from .database import Database
from .event import Event
from .event_generator import EventGenerator
from .parameters import Parameters
from .snapshot_person import SnapshotPerson


class Person:
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
        self.elapsed = 0.0
        self.infection_risk = 0.0
        self.CO2_level = 0.0
        self.last_updated = 0

        self.snapshot = SnapshotPerson()

    @classmethod
    def reset(cls) -> None:
        Person.id = -1

    @staticmethod
    def next() -> None:
        Person.id += 1

    def start(self) -> None:
        logging.info("[%.2f] Person %d starting up" % (self.env.now, self.id))
        self.env.process(self.process())

    def process(self) -> None:
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

            # move from current place to new one
            # TODO: review if we want to save only new places or all of them
            # if self.event is not None and self.event.place is not None and self.place != self.event.place and not self.event.place.full():
            if self.event is not None and self.event.place is not None and not self.event.place.full():
                # remove from current place
                if self.place is not None:
                    self.place.remove_person(self)

                # add to new place
                self.place = self.event.place
                self.place.add_person(self)

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
        try:
            yield self.env.timeout(self.duration)
        except Interrupt:
            # TODO: review this exception
            # print("interrupted")
            pass

    def assign_event(self, event: Event) -> None:
        if self.current_process is not None and not self.current_process.triggered:
            self.current_process.interrupt("Need to go!")
            logging.info("[%.2f] Person %d interrupted current event" % (self.env.now, self.id))
        self.event = event
        self.generator.consume_activity(event.model)

    # TODO: review if we need to update the risk of infected people as well
    # TODO: review infection risk metric: average vs cumulative
    def update(self, elapsed: float, infection_risk: float, CO2_level: float) -> None:
        self.elapsed += elapsed
        # self.infection_risk += elapsed * (infection_risk - self.infection_risk) / self.elapsed
        self.infection_risk += infection_risk
        self.CO2_level += elapsed * (CO2_level - self.CO2_level) / self.elapsed

    def save_snapshot(self) -> None:
        self.snapshot.set("run", self.db.run)
        self.snapshot.set("time", self.env.now, 0)
        self.snapshot.set("person", self.id)
        self.snapshot.set("status", self.status)
        self.snapshot.set("place", self.place.id)
        self.snapshot.set("event", self.model.id)
        self.snapshot.set("CO2_level", self.CO2_level, 2)
        self.snapshot.set("infection_risk", self.infection_risk, 6)
        self.db.results.write_person(self.snapshot)

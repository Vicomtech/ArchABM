import logging

from simpy import Environment, Interrupt
from .Event import Event
from .Database import Database
from .Parameters import Parameters
from .EventGenerator import EventGenerator
from .PersonFrame import PersonFrame


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
        self.risk = 0.0
        self.last_updated = 0

        self.person_frame = PersonFrame()

    @classmethod
    def reset(cls) -> None:
        Person.id = -1

    def next(self) -> None:
        Person.id += 1

    def start(self) -> None:
        logging.info("[%.2f] Person %d starting up" % (self.env.now, self.id))
        self.env.process(self.process())

    def process(self) -> None:
        cont = 0
        cont_max = 1000
        while True:
            # Generate Event
            while self.event is None:
                self.event = self.generator.generate(self.env.now, self)
            self.model = self.event.model
            self.duration = self.event.duration
            activity = self.model.params.activity

            # print(self.event, self.event.place, self.place, self.event.place.full())

            # Move from current place to new one
            if self.event is not None and self.place != self.event.place and not self.event.place.full():
                # Remove from current place
                if self.place is not None:
                    self.place.remove_person(self)

                # Add to new place
                self.place = self.event.place
                self.place.add_person(self)

                # Save data (if first event or elapsed time > 0)
                elapsed = self.env.now - self.last_updated
                if elapsed > 0 or cont == 0:
                    self.save_person_frame()

            logging.info(
                "[%.2f] Person %d event %s at place %s for %d minutes"
                % (
                    self.env.now,
                    self.id,
                    self.model.params.activity,
                    self.place.params.name,
                    self.duration,
                )
            )

            self.event = None
            # print("DOING", self.id, self.activity, self.duration)
            self.last_updated = self.env.now
            self.current_process = self.env.process(self.wait())
            yield self.current_process
            # print("#####", self.id, self.activity, self.duration)

            cont += 1
            if cont > cont_max:
                break

    def wait(self) -> None:
        try:
            yield self.env.timeout(self.duration)
        except Interrupt:
            # print("interrupted")
            pass

    def assign_event(self, event: Event) -> None:
        if self.current_process is not None and not self.current_process.triggered:
            self.current_process.interrupt("Need to go!")
            logging.info(
                "[%.2f] Person %d interrupted current event" % (self.env.now, self.id)
            )
        self.event = event
        self.generator.consume_activity(event.model)

    def update_risk(self, risk: float) -> None:
        self.risk += risk

    def save_person_frame(self) -> None:
        # self.person_frame.reset()
        self.person_frame.set("run", self.db.run)
        self.person_frame.set("time", self.env.now, 0)
        self.person_frame.set("person", self.id)
        self.person_frame.set("place", self.place.id)
        self.person_frame.set("event", self.model.id)
        self.person_frame.set("risk", self.risk)
        self.db.results.write_person(self.person_frame)

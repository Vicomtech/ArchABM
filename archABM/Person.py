import logging
from .EventGenerator import EventGenerator
from .PersonFrame import PersonFrame
import simpy
import copy


class Person:
    id = -1

    def __init__(self, env, db, params):
        self.next()
        self.id = Person.id

        self.env = env
        self.db = db

        self.params = params

        self.place = None
        self.risk = 0.0
        self.status = None  # TODO: remove

        self.generator = EventGenerator(self, env, db)

        self.person_frame = PersonFrame()
        self.current_process = None
        self.event = None

    @classmethod
    def reset(cls):
        Person.id = -1

    def next(self):
        Person.id += 1

    def start(self):
        logging.info("[%.2f] Person %d starting up" % (self.env.now, self.id))
        self.env.process(self.process())

        #     self.event = task.event
        #     yield self.env.timeout(task.duration)

    def process(self):
        cont = 0
        cont_max = 1000
        while True:
            # Generate Event
            while self.event is None:
                self.event = self.generator.generate(self.env.now)
            self.model = self.event.model
            self.duration = self.event.duration
            activity = self.model.params.activity

            # print(self.event, self.event.place, self.place, self.event.place.full())

            # Move from current place to new one
            if self.place != self.event.place and not self.event.place.full():
                # Remove from current place
                if self.place is not None:
                    self.place.remove_person(self)

                # Add to new place
                self.place = self.event.place
                self.place.add_person(self)

                # Save data
                self.save_person_frame()

            logging.info("[%.2f] Person %d event %s at place %s for %d minutes" % (self.env.now, self.id, self.model.params.activity, self.place.params.name, self.duration,))

            self.event = None
            # print("DOING", self.id, self.activity, self.duration)
            self.current_process = self.env.process(self.wait())
            yield self.current_process
            # print("#####", self.id, self.activity, self.duration)

            cont += 1
            if cont > cont_max:
                break

    def wait(self):
        try:
            yield self.env.timeout(self.duration)
        except simpy.Interrupt:
            # print("interrupted")
            pass

    def assign_event(self, event):
        if self.current_process is not None and not self.current_process.triggered:
            self.current_process.interrupt("Need to go!")
            logging.info("[%.2f] Person %d interrupted current event" % (self.env.now, self.id))
        self.event = event
        self.generator.consume_activity(event.model)

    def update_risk(self, risk):
        self.risk += risk

    def save_person_frame(self):
        # self.person_frame.reset()
        self.person_frame.set("run", self.db.run)
        self.person_frame.set("time", self.env.now, 0)
        self.person_frame.set("person", self.id)
        self.person_frame.set("place", self.place.id)
        self.person_frame.set("event", self.model.id)
        self.person_frame.set("risk", self.risk)
        self.db.results.write_person(self.person_frame)

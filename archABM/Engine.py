import simpy

from .Creator import Creator
from .Database import Database
import logging

from .Actions import Actions


class Engine:
    def __init__(self, config):
        self.config = config

        self.env = simpy.Environment()
        self.db = Database(self.env, self.config)

        god = Creator(self.env, self.config, self.db)

        events = god.create_events()
        self.db.set_events(events)

        places = god.create_places()
        self.db.set_places(places)

        # virus = god.create_virus()

        people = god.create_people()
        self.db.set_people(people)

        options = god.create_options()
        self.db.set_options(options)

        actions = god.create_actions()
        self.db.set_actions(actions)

        # self.env.process(actions.create_random_event(600))

    def run(self, until):
        # print("Simulation Started")
        self.env.run(until)
        # print("Simulation Finished")

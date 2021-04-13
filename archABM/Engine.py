import simpy
import logging

from .Creator import Creator
from .Database import Database
from .Actions import Actions
from .Results import Results


class Engine:
    def __init__(self, config):
        self.config = config
        self.db = Database()
        self.db.results = Results(self.config)

    def setup(self):
        self.env = simpy.Environment()
        self.db.next()

        god = Creator(self.env, self.config, self.db)
        self.db.events = god.create_events()
        self.db.places = god.create_places()
        self.db.options = god.create_options()
        self.db.actions = god.create_actions()
        self.db.people = god.create_people()

    def run(self, until, num=1):
        # print("Simulation Started")
        for i in range(num):
            self.setup()
            self.env.run(until)
        # print("Simulation Finished")

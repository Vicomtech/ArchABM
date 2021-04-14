import simpy
import logging
from tqdm import tqdm

from .Creator import Creator
from .Database import Database
from .Actions import Actions
from .Results import Results


class Engine:
    def __init__(self, config):
        self.config = config
        self.preprocess()

        self.db = Database()
        self.db.results = Results(self.config)

    def preprocess(self):
        people = []
        cont = 0
        for p in self.config["people"]:
            num_people = p.pop("num_people")
            for i in range(num_people):
                p["name"] = "person" + str(cont)
                people.append(p.copy())
                cont += 1
        self.config["people"] = people


    def setup(self):
        self.env = simpy.Environment()
        self.db.next()

        god = Creator(self.env, self.config, self.db)
        self.db.options = god.create_options()
        self.db.events = god.create_events()
        self.db.places = god.create_places()
        self.db.actions = god.create_actions()
        self.db.people = god.create_people()
        return

    def run(self, until, num=1):
        # print("Simulation Started")
        with tqdm(total=num) as pbar:
            for i in range(num):
                self.setup()
                self.env.run(until)
                pbar.update(1)
        # print("Simulation Finished")
        return self.db.results.done()

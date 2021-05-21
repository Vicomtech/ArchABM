from simpy import Environment
from tqdm import tqdm
from .Creator import Creator
from .Database import Database
from .Results import Results


class Engine:
    def __init__(self, config: dict) -> None:
        self.config = config
        self.preprocess()

        self.db = Database()
        self.db.results = Results(self.config)

    def preprocess(self) -> None:
        people = []
        cont = 0
        for person in self.config["people"]:
            num_people = person.pop("num_people")
            for i in range(num_people):
                person["name"] = "person" + str(cont)
                people.append(person.copy())
                cont += 1
        self.config["people"] = people

    def setup(self) -> None:
        self.env = Environment()
        self.db.next()

        god = Creator(self.env, self.config, self.db)
        self.db.options = god.create_options()
        self.db.events = god.create_events()
        self.db.places = god.create_places()
        self.db.actions = god.create_actions()
        self.db.people = god.create_people()

    def run(self, until: int = None, number_runs: int = None):
        if until is None:
            until = 1440
        if number_runs is None:
            number_runs = self.config["options"]["number_runs"]

        with tqdm(total=number_runs) as pbar:
            for i in range(number_runs):
                self.setup()
                self.env.run(until)
                pbar.update(1)
        return self.db.results.done()

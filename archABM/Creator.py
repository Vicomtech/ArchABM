from random import sample
from typing import List

from simpy import Environment

from .Actions import Actions
from .Database import Database
from .EventModel import EventModel
from .Options import Options
from .Parameters import Parameters
from .Person import Person
from .Place import Place


class Creator:
    def __init__(self, env: Environment, config: dict, db: Database) -> None:
        self.env = env
        self.config = config
        self.db = db

        Person.reset()
        Place.reset()
        EventModel.reset()

    def create_options(self) -> Options:
        p = self.config["options"]
        params = Parameters(p)
        options = Options(self.env, self.db, params)

        return options

    def create_events(self) -> List[EventModel]:
        events = []
        for e in self.config["events"]:
            params = Parameters(e)
            event = EventModel(params)
            events.append(event)

        return events

    def create_places(self) -> List[Place]:
        places = []
        for p in self.config["places"]:
            params = Parameters(p)
            place = Place(self.env, self.db, params)
            places.append(place)

        return places

    def create_actions(self) -> Actions:
        return Actions(self.env, self.db)

    def create_people(self) -> List[Person]:
        people = []
        for p in self.config["people"]:
            params = Parameters(p)
            person = Person(self.env, self.db, params)
            person.start()
            people.append(person)

        num_people = len(people)
        num_infected = int(max(1, self.config["options"]["ratio_infected"] * num_people))
        for p in sample(people, num_infected):
            p.status = 1

        return people

    def create_model(self):
        options = self.config["options"]
        selection = options["model"]
        params = Parameters(options["model_parameters"][selection])
        model = None
        if selection == "MaxPlanck":
            from .AerosolModelMaxPlanck import AerosolModelMaxPlanck

            model = AerosolModelMaxPlanck(params)
        elif selection == "MIT":
            from .AerosolModelMIT import AerosolModelMIT

            model = AerosolModelMIT(params)
        elif selection == "Colorado":
            from .AerosolModelColorado import AerosolModelColorado

            model = AerosolModelColorado(params)

        return model

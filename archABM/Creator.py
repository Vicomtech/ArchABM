from .EventModel import EventModel
from .Place import Place

# from .PlaceParameters import PlaceParameters
from .Person import Person

# from .PersonParameters import PersonParameters
from .Parameters import Parameters
from .Actions import Actions
from .Options import Options

import numpy as np


class Creator:
    def __init__(self, env, config, db):
        self.env = env
        self.config = config
        self.db = db

        Person.reset()
        Place.reset()

    def create_events(self):
        events = []
        for e in self.config["Events"].replace({np.nan: None}).to_dict("records"):
            params = Parameters(e)
            # event = EventModel(
            #     e["activity"],
            #     e["schedule"],
            #     e["repeat_min"],
            #     e["repeat_max"],
            #     e["duration_min"],
            #     e["duration_max"],
            # ) # TODO: replace with Parameter? DONE
            event = EventModel(params)
            events.append(event)

        return events

    def create_places(self):
        places = []
        df = self.config["Places"]
        for p in self.config["Places"].replace({np.nan: None}).to_dict("records"):
            params = Parameters(p)
            # params = PlaceParameters(
            #     p["name"],
            #     p["event"],
            #     p["building"],
            #     p["department"],
            #     p["area"],
            #     p["height"],
            # )
            # TODO: replace event string by event_model instance DONE
            place = Place(self.env, self.db, params)
            places.append(place)

        return places

    def create_virus(self):
        pass

    def create_people(self):
        people = []
        for p in self.config["People"].replace({np.nan: None}).to_dict("records"):
            params = Parameters(p)
            # params = PersonParameters(p["name"], p["department"])
            # TODO: review department string DONE
            person = Person(self.env, self.db, params)
            person.start()
            people.append(person)
            # break

        return people

    def create_actions(self):
        return Actions(self.env, self.db)

    def create_options(self):
        p = self.config["Options"].replace({np.nan: None}).set_index("option")["value"].to_dict()
        params = Parameters(p)
        options = Options(self.env, self.db, params)

        return options

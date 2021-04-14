from .EventModel import EventModel
from .Place import Place
from .Person import Person
from .Parameters import Parameters
from .Actions import Actions
from .Options import Options

class Creator:
    def __init__(self, env, config, db):
        self.env = env
        self.config = config
        self.db = db

        Person.reset()
        Place.reset()

    def create_options(self):
        p = self.config["options"]
        params = Parameters(p)
        options = Options(self.env, self.db, params)

        return options

    def create_events(self):
        events = []
        for e in self.config["events"]:
            params = Parameters(e)
            event = EventModel(params)
            events.append(event)

        return events

    def create_places(self):
        places = []
        for p in self.config["places"]:
            params = Parameters(p)
            place = Place(self.env, self.db, params)
            places.append(place)

        return places

    def create_actions(self):
        return Actions(self.env, self.db)

    def create_people(self):
        people = []
        for p in self.config["people"]:
            params = Parameters(p)
            person = Person(self.env, self.db, params)
            person.start()
            people.append(person)

        return people



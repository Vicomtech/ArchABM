import logging
import random
from typing import List

from simpy import Environment

from .Database import Database
from .Event import Event
from .EventModel import EventModel
from .Person import Person
from .Place import Place


class Actions:
    def __init__(self, env: Environment, db: Database) -> None:
        self.env = env
        self.db = db
        # self.flag = None

    def find_place(self, model: EventModel, person: Person) -> None:
        places = self.db.places
        random.shuffle(places)
        # if self.flag is None:
        #     random.shuffle(places)
        #     self.flag = 0
        for place in places:
            if place.params.activity == model.params.activity:
                # check if place is allowed and not full
                if place.params.allow and not place.full():
                    # check if movement between buildings is not allowed
                    if not self.db.options.params.movement_buildings:
                        # check if person has a place (initial condition)
                        if person.place is not None:
                            # check if person has building defined
                            if person.params.building is not None:
                                # check if place has building defined
                                if place.params.building is not None:
                                    if person.params.building != place.params.building:
                                        continue

                    if not self.db.options.params.movement_department:
                        # check if person has a place (initial condition)
                        if person.place is not None:
                            # check if person has department defined
                            if person.params.department is not None:
                                # check if place has department defined
                                if place.params.department is not None:
                                    if person.params.department not in place.params.department:
                                        continue

                    return place
        return None

    @staticmethod
    def create_event(model: EventModel, place: Place, duration: int) -> Event:
        return Event(model, place, duration)

    @staticmethod
    def assign_event(event: Event, people: List[Person]) -> None:
        for person in people:
            person.assign_event(event)

    def create_collective_event(self, model: EventModel, place: Place, duration: int, person: Person) -> None:
        # create event
        event = self.create_event(model, place, duration)

        # select people
        people = self.db.people
        # from the same building if option applied
        if not self.db.options.params.movement_buildings:
            building = event.place.params.building
            if building is not None:
                people_filter = []
                for p in people:
                    if p.place is not None:
                        if p.place.params.building is None or p.place.params.building == building:
                            people_filter.append(p)
                people = people_filter

        # from the same department if option applied
        if not self.db.options.params.movement_department:
            department = event.place.params.department
            if department is not None:
                people_filter = []
                for p in people:
                    if p.params.department is None or p.params.department in department:
                        people_filter.append(p)
                people = people_filter

        if len(people) > 1:
            num_people = place.people_attending()
            num_people = min(len(people), num_people)
            people = random.sample(people, k=num_people)
            people = [p for p in people if p.generator.valid_activity(model) and p.model != model]

        logging.info(
            "[%.2f] Person %d invoked collective event %s at place %s for %d minutes for %d people"
            % (self.env.now, person.id, model.params.activity, place.params.name, duration, len(people),)
        )

        self.assign_event(event, people)
        return event

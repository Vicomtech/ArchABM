from .Event import Event
# import numpy as np
import random


class Actions:
    def __init__(self, env, db):
        self.env = env
        self.db = db

        self.flag = None

    def find_place(self, model, person):
        places = self.db.places
        if self.flag is None:
            random.shuffle(places)
            self.flag = 0
        # print("FIND PLACE FOR", model.params.activity, person.params.name)
        # if person is None:
        #     person = np.random.choice(self.db.people, size=None, replace=None).tolist()
        #     places = [p for p in places if p.event.params.shared] # TODO: REVIEW THIS PLEASE
        # for place in np.random.permutation(places):
        # for place in random.sample(places, k=len(places)):
        for place in places:
            if place.params.activity == model.params.activity:
                # if person.place is not None:
                #     print("FROM: ", person.place.params.name, "TO: ", place.params.name)
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

                    # print("GOTO:", place.params.name)
                    return place
        # print("NOT PLACE", activity, person.params.name)
        return None

    def create_event(self, model, place, duration):
        return Event(model, place, duration)

    def assign_event(self, event, people):
        for person in people:
            person.assign_event(event)

    # TODO: remove method
    def create_random_event(self, when):
        # wait until start of event
        yield self.env.timeout(when)

        # select activity
        model = np.random.choice(self.db.events)
        activity = model.params.activity

        # set duration
        duration = 100

        # select people
        num_people = 3
        num_people = min(len(self.db.people), num_people)
        people = np.random.choice(self.db.people, size=num_people, replace=None)

        event = self.create_event(activity, duration)
        # print(len(people), event.activity, event.duration, event.place)
        self.assign_event(event, people)

    # TODO: remove method
    def go_home(self, activity, duration):
        activity = "home"
        duration = 1e4
        people = [p for p in self.db.people if p.status == "positive"]

        event = self.create_event(activity, duration)
        self.assign_event(event, people)

    # TODO: remove method
    def create_meeting(self, duration):
        activity = "meeting"
        duration = 30
        num_people = 10

        # if we add more parameters to the people
        # we can give more weight to different profiles
        # for example, that DARs are always present on meetings

    def create_collective_event(self, model, place, duration, person):

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
            people = [p for p in people if p.generator.valid_activity(model)]
            # people = np.random.choice(people, size=num_people, replace=None).tolist()
        # always add invoking person to the people
        if person not in people:
            people.append(person)
        # print(
        #     "Action",
        #     round(self.env.now),
        #     len(people),
        #     event.activity,
        #     event.duration,
        #     event.place.params.name,
        # )

        self.assign_event(event, people)
        return None

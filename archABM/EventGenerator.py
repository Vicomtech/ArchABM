import numpy as np
import random
from .Event import Event


class EventGenerator:
    def __init__(self, person, env, db):
        self.person = person
        self.env = env
        self.db = db

        # get only allowed events
        # self.models = [m for m in self.db.events if m.params.allow]
        # generate new if not collective
        # self.models = [m.new() if not m.params.collective else m for m in self.models]

        # generate new in allowed events
        self.models = [m.new() for m in self.db.events if m.params.allow]
        # TODO: careful with available models => infinite loop

        self.activities = [m.params.activity for m in self.models]

    def generate(self, now):
        # Get probabilities for each model event
        num_people = len(self.db.people)
        p = [m.probability(now) for m in self.models]
        v = [m.valid() for m in self.models]

        # print(round(now), p, v)

        # Select event model
        if sum(p) > 0:
            # p = p / np.sum(p)
            model = random.choices(self.models, weights=p)[0]
            # model = np.random.choice(self.models, size=None, replace=False, p=p)
        elif sum(v) > 0:
            # TODO: what happens if all probabilities are zero? => random event? DONE
            # v = v / np.sum(v)
            model = random.choices(self.models, weights=v)[0]
            # model = np.random.choice(self.models, size=None, replace=False, p=v)
            # print(now, p, v, model)
        else:
            model = random.choice(self.models)
            # model = np.random.choice(self.models, size=None, replace=False)
        # model.consume() # TODO: consume once if not collective, consume for every person if collective

        # Create event based on selected model
        activity = model.params.activity
        duration = model.duration(now)
        # duration += 0.001
        place = self.db.actions.find_place(activity, self.person)
        if place is None:
            return None
        if model.params.collective:
            # print("COLLECTIVE", place.params.name)
            return self.db.actions.create_collective_event(activity, place, duration, self.person)
        else:
            model.consume()
            return self.db.actions.create_event(activity, place, duration)

    def consume_activity(self, activity):
        for m in self.models:
            if m.params.activity == activity:
                m.consume()

    def valid_activity(self, activity):
        for m in self.models:
            if m.params.activity == activity:
                return m.valid()

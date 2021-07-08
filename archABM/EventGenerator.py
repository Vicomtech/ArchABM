import random

from simpy import Environment

from .Database import Database


class EventGenerator:
    def __init__(self, env: Environment, db: Database):
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

    def generate(self, now, person):
        # Get probabilities for each model event
        p = [m.probability(now) for m in self.models]
        v = [m.valid() for m in self.models]

        # Select event model
        if sum(p) > 0:
            model = random.choices(self.models, weights=p)[0]
        elif sum(v) > 0:
            model = random.choices(self.models, weights=v)[0]
        else:
            model = random.choice(self.models)

        # Create event based on selected model
        activity = model.params.activity
        duration = model.duration(now)
        # duration += 0.001
        place = self.db.actions.find_place(model, person)
        if place is None:
            return None
        if model.params.collective:
            return self.db.actions.create_collective_event(model, place, duration, person)
        else:
            model.consume()
            return self.db.actions.create_event(model, place, duration)

    def consume_activity(self, model):
        for m in self.models:
            if m.params.activity == model.params.activity:
                m.consume()

    def valid_activity(self, model):
        for m in self.models:
            if m.params.activity == model.params.activity:
                return m.valid()

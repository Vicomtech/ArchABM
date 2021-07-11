import random

from simpy import Environment

from .database import Database
from .event_model import EventModel

class EventGenerator:
    """Generates events

    An event is defined by an activity :obj:`EventModel`, that happens at a given
    :obj:`Place`, for a finite period of time, in minutes (duration).

    A event generator has certain event models to choose from, 
    each one related to an activity.


    """
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

    def generate(self, now: int, person):
        """Generates events

        First, it computes the probabilities and the validity 
        of each :obj:`EventModel` at the current timestamp. 
        Then, the activity is selected based on these probabilities as follows:

        * If there exists any probability among the list of :obj:`EventModel`, the activity is selected randomly according to the relative probabilities.
        * If all :obj:`EventModel` have ``0`` probability, then the activity is selected randomly among the valid ones.
        * Otherwise a random activity is returned.

        Once the activity type :obj:`EventModel` has been selected, 
        the event duration can computed and the :obj:`Place` can also be chosen. 

        The selected activity is counted (consumed) from the list of :obj:`EventModel` of the invoking person.
        Collective activities are consumed individually after the current event interruption.         

        Args:
            now (int): current timestamp in minutes
            person (Person): person that invokes the event generation

        Returns:
            Event: generated :obj:`event`, which is a set of 
            a) activity :obj:`EventModel`, 
            b) :obj:`place` and 
            c) duration.
        """
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

    def consume_activity(self, model: EventModel):
        """Consumes a unit from a given :obj:`EventModel`.

        Args:
            model (EventModel): event model to consume from
        """
        for m in self.models:
            if m.params.activity == model.params.activity:
                m.consume()

    def valid_activity(self, model: EventModel):
        """Checks whether a given :obj:`EventModel` is valid.

        Args:
            model (EventModel): event model to check validity from

        Returns:
            [bool]: whether the event model is valid
        """
        for m in self.models:
            if m.params.activity == model.params.activity:
                return m.valid()

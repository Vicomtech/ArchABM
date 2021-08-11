import random

from simpy import Environment

from .database import Database
from .event_model import EventModel


class EventGenerator:
    """Generates events

    An event is defined by an activity :class:`~archABM.event_model.EventModel`, that happens at a given physical location
    :class:`~archABM.place.Place`, for a finite period of time, in minutes (duration).

    A event generator has certain event models to choose from, 
    each one related to an activity.

    """

    env: Environment
    db: Database
    models: list
    activities: list

    def __init__(self, env: Environment, db: Database):
        self.env = env
        self.db = db

        # generate new for allowed events
        self.models = [m.new() for m in self.db.events if m.params.allow]
        self.activities = [m.params.activity for m in self.models]

    def generate(self, now: int, person):
        """Generates events

        First, it computes the probabilities and the validity 
        of each :class:`~archABM.event_model.EventModel` at the current timestamp. 
        Then, the activity is selected based on these probabilities as follows:

        * If there exists any probability among the list of :class:`~archABM.event_model.EventModel`, the activity is selected randomly according to the relative probabilities.
        * If all :class:`~archABM.event_model.EventModel` have ``0`` probability, then the activity is selected randomly among the valid ones.
        * Otherwise a random activity is returned.

        Once the activity type :class:`~archABM.event_model.EventModel` has been selected, 
        the event duration can computed and the physical location :class:`~archABM.place.Place`` can also be chosen. 

        The selected activity is counted (consumed) from the list of :class:`~archABM.event_model.EventModel` of the invoking person.

        .. note::
            Collective activities are consumed individually after the current event interruption.         

        Args:
            now (int): current timestamp in minutes
            person (Person): person that invokes the event generation

        Returns:
            Event: generated :class:`~archABM.event.Event`, which is a set of 
            a) activity :class:`~archABM.event_model.EventModel`, 
            b) physical location :class:`~archABM.place.Place`` and 
            c) time duration.
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
        """Consumes a unit from a given :class:`~archABM.event_model.EventModel`.

        Args:
            model (EventModel): event model to consume from
        """
        for m in self.models:
            if m.params.activity == model.params.activity:
                m.consume()

    def valid_activity(self, model: EventModel):
        """Checks whether a given :class:`~archABM.event_model.EventModel` is valid.

        Args:
            model (EventModel): event model to check validity from

        Returns:
            [bool]: whether the event model is valid
        """
        for m in self.models:
            if m.params.activity == model.params.activity:
                return m.valid()

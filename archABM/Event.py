from .Place import Place
from .EventModel import EventModel


class Event:
    def __init__(self, model: EventModel, place: Place, duration: int) -> None:
        self.model = model
        self.place = place
        self.duration = duration

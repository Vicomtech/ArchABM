from .EventModel import EventModel
from .Place import Place


class Event:
    def __init__(self, model: EventModel, place: Place, duration: int) -> None:
        self.model = model
        self.place = place
        self.duration = duration

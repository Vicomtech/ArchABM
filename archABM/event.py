from .event_model import EventModel
from .place import Place


class Event:
    """Event primitive
    
    An event is defined by an activity :class:`~archABM.event_model.EventModel`, that happens at a given physical location 
    :class:`~archABM.place.Place``, for a finite period of time, in minutes (duration).
    """

    model: EventModel
    place: Place
    duration: int

    def __init__(self, model: EventModel, place: Place, duration: int) -> None:
        self.model = model
        self.place = place
        self.duration = duration

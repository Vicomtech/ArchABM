class Database:
    """In-memory database of the simulation components

    It registers:
    :class:`~archABM.options.Options`, 
    :class:`~archABM.aerosol_model.AerosolModel`,
    :class:`~archABM.actions.Actions`, 
    :class:`~archABM.event.Event` list, 
    :class:`~archABM.place.Place` list, 
    :class:`~archABM.person.Person` list, 
    simulation run ID.
    """

    model: None
    actions: None
    options: None
    events: list
    places: list
    people: list
    run: int

    def __init__(self) -> None:
        self.options = None
        self.model = None
        self.actions = None
        self.events = []
        self.places = []
        self.people = []

        self.run = -1

    def next(self) -> None:
        """Increments one unit the simulation run ID"""
        self.run += 1

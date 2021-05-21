class Database:
    def __init__(self) -> None:
        self.events = []
        self.places = []
        self.people = []
        self.actions = None
        self.options = None

        self.run = -1

    def next(self) -> None:
        self.run += 1

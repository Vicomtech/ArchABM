class Database:
    def __init__(self):
        self.events = []
        self.places = []
        self.people = []
        self.actions = None
        self.options = None

        self.id = -1

    def next(self):
        self.id += 1

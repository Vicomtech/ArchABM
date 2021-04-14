class Database:
    def __init__(self):
        self.events = []
        self.places = []
        self.people = []
        self.actions = None
        self.options = None

        self.run = -1

    def next(self):
        self.run += 1

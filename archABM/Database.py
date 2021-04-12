from .Results import Results


class Database:
    def __init__(self, env, config):
        self.env = env  # TODO: maybe remove env from database
        self.config = config
        self.results = Results(self.config)

        self.events = []
        self.places = []
        self.people = []
        self.actions = None
        self.options = None
        # self.virus = []

    def set_events(self, events):
        self.events = events

    def set_places(self, places):
        self.places = places

    def set_people(self, people):
        self.people = people

    def set_virus(self, virus):
        self.virus = virus

    def set_schedule(self, schedule):
        self.schedule = schedule

    def set_policy(self, policy):
        self.policy = policy

    def set_actions(self, actions):
        self.actions = actions

    def set_options(self, options):
        self.options = options

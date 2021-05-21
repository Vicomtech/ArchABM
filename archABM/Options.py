from simpy import Environment
from .Database import Database
from .Parameters import Parameters


class Options:
    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.env = env
        self.db = db
        self.params = params

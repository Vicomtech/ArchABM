from simpy import Environment

from .database import Database
from .parameters import Parameters


class Options:
    """Stores general options for the simulation"""

    env: Environment
    db: Database
    params: Parameters

    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.env = env
        self.db = db
        self.params = params

from jsonschema import validate
from simpy import Environment
from tqdm import tqdm

from .creator import Creator
from .database import Database
from .results import Results

import json
import os
import copy


class Engine:
    """Core class of the archABM package
    
    Launches the agent-based simulation with the specified configuration.
    """

    config: dict
    db: Database
    env: Environment

    def __init__(self, config: dict) -> None:
        schema = self.retrieve_schema()
        validate(instance=config, schema=schema)

        self.config = self.preprocess(config)

    def retrieve_schema(self):
        """Get configuration file JSON schema

        Returns:
            dict: json-schema
        """
        dir_path = os.path.dirname(os.path.realpath(__file__))
        with open(dir_path + "/schema.json", "r") as f:
            schema = json.load(f)
        return schema

    def preprocess(self, config) -> None:
        """Processes the configuration dictionary to generate people.

        Based on the specified configuration of number of people per group,
        this method generates an array of people, and assignes a incremental name to each person.
        """
        config = copy.deepcopy(config)

        num_people = 0
        for person in config["people"]:
            num_people += person["num_people"]

        for place in config["places"]:
            if place["capacity"] is None:
                place["capacity"] = num_people + 1

        people = []
        cont = 0
        for person in config["people"]:
            num_people = person.pop("num_people")
            for i in range(num_people):
                person["name"] = "person" + str(cont)
                people.append(person.copy())
                cont += 1
        config["people"] = people
        return config

    def setup(self) -> None:
        """Setup for a simulation run.

        Creates the environment and the required assets to run a simulation:
        :class:`~archABM.options.Options`, 
        :class:`~archABM.aerosol_model.AerosolModel`,
        :class:`~archABM.event.Event`, 
        :class:`~archABM.place.Place`, 
        :class:`~archABM.actions.Actions`, 
        :class:`~archABM.person.Person`.
        """
        self.env = Environment()
        self.db.next()

        god = Creator(self.env, self.config, self.db)
        self.db.options = god.create_options()
        self.db.model = god.create_model()
        self.db.events = god.create_events()
        self.db.places = god.create_places()
        self.db.actions = god.create_actions()
        self.db.people = god.create_people()

    def run(self, until: int = None, number_runs: int = None) -> dict:
        """Launches a batch of simulations

        Args:
            until (int, optional): duration of each simulation, in minutes. Defaults to None.
            number_runs (int, optional): number of simulation runs. Defaults to None.

        Returns:
            dict: simulation history and configuration
        """
        self.db = Database()
        self.db.results = Results(self.config)

        if until is None:
            until = 1440
        if number_runs is None:
            number_runs = self.config["options"]["number_runs"]

        with tqdm(total=number_runs) as pbar:
            for i in range(number_runs):
                self.setup()
                self.env.run(until)
                pbar.update(1)
        return self.db.results.done()

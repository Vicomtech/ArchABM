import datetime
import json
import logging
import os

from .person import Person
from .place import Place
from .snapshot_person import SnapshotPerson
from .snapshot_place import SnapshotPlace


class Results:
    """Simulation history processing and export"""

    output: dict

    def __init__(self, config: dict) -> None:
        # TODO: review hardcoded names
        self.people_name = "people"
        self.places_name = "places"
        self.results_name = "results"
        self.config_name = "config"
        self.output_name = "output"
        self.log_name = "app.log"

        self.config = config

        self.log = False
        self.save_log = self.config["options"]["save_log"]
        self.save_config = self.config["options"]["save_config"]
        self.save_csv = self.config["options"]["save_csv"]
        self.save_json = self.config["options"]["save_json"]
        self.return_output = self.config["options"]["return_output"]

        self.output = None

        if self.save_log or self.save_config or self.save_csv or self.save_json:
            self.mkpath()
            self.mkdir()

        self.setup_log()
        if self.save_config:
            self.write_config()
        if self.save_csv:
            self.open_people_csv()
            self.open_places_csv()
        if self.save_json:
            self.open_json()
        if self.return_output or self.save_json:
            self.init_results()

    def mkpath(self) -> None:
        """Creates the path where the simulation results should be saved. 
        
        If the ``directory`` option is specified, another folder level is added to the path.
        """
        cwd = os.getcwd()
        now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")
        folder = "results"
        self.path = os.path.join(cwd, folder, now)
        if "directory" in self.config["options"]:
            directory = self.config["options"]["directory"]
            if directory is not None:
                self.path = os.path.join(cwd, folder, directory, now)

    def mkdir(self) -> None:
        """Creates the directory where the simulation results should be saved."""
        os.makedirs(self.path)

    def setup_log(self) -> None:
        """Logging setup"""
        if self.save_log:
            logging.basicConfig(
                filename=os.path.join(self.path, self.log_name), filemode="w", format="%(message)s", level=logging.INFO,
            )
        elif self.log:
            logging.basicConfig(format="%(message)s", level=logging.INFO)
        else:
            logging.disable(logging.INFO)

    def open_people_csv(self) -> None:
        """Creates and opens the *csv* file to save people state history"""
        self.people_csv = open(os.path.join(self.path, self.people_name + ".csv"), "a")
        self.people_csv.write(SnapshotPerson.get_header())

    def close_people_csv(self) -> None:
        """Closes the people *csv* file"""
        self.people_csv.close()

    def open_places_csv(self) -> None:
        """Creates and opens the *csv* file to save places state history"""
        self.places_csv = open(os.path.join(self.path, self.places_name + ".csv"), "a")
        self.places_csv.write(SnapshotPlace.get_header())

    def close_places_csv(self) -> None:
        """Closes the places *csv* file"""
        self.places_csv.close()

    def open_json(self) -> None:
        """Creates and opens the *json* file to save all results"""
        self.output_json = open(os.path.join(self.path, self.output_name + ".json"), "w")

    def write_json(self) -> None:
        """Writes the :attr:`output` dictionary to the *json* file"""
        json.dump(self.output, self.output_json)

    def close_json(self) -> None:
        """Closes the *json* file"""
        self.output_json.close()

    def init_results(self) -> None:
        """Initializes the results dictionary"""
        self.output = {}
        self.results = dict.fromkeys([self.people_name, self.places_name], {})
        self.results[self.people_name] = dict.fromkeys(SnapshotPerson.header)
        self.results[self.places_name] = dict.fromkeys(SnapshotPlace.header)

        self.output[self.config_name] = self.config
        self.output[self.results_name] = self.results

        for key in SnapshotPerson.header:
            self.results[self.people_name][key] = []
        for key in SnapshotPlace.header:
            self.results[self.places_name][key] = []

    def write_person(self, person: Person) -> None:
        """Appends a new row to the person state history.

        Args:
            person (Person): person state to be saved
        """
        if self.save_csv:
            self.people_csv.write(person.get_data())
        if self.save_json or self.return_output:
            for key, value in person.store.items():
                self.results[self.people_name][key].append(value)

    def write_place(self, place: Place) -> None:
        """Appends a new row to the place state history.

        Args:
            place (Place): place state to be saved
        """
        if self.save_csv:
            self.places_csv.write(place.get_data())
        if self.save_json or self.return_output:
            for key, value in place.store.items():
                self.results[self.places_name][key].append(value)

    def write_config(self) -> None:
        """Writes the configuration dictionary into a *json* file."""
        with open(os.path.join(self.path, self.config_name + ".json"), "w") as f:
            json.dump(self.config, f)

    def done(self) -> None:
        """Closes all file connections and returns a :obj:`dict` with the complete simulation history.

        Returns:
            dict: complete simulation history
        """
        if self.save_csv:
            self.close_people_csv()
            self.close_places_csv()
        if self.save_json:
            self.write_json()
            self.close_json()
        if self.return_output:
            return self.output
        return None

import os
import datetime
import json
import logging
from .Place import Place
from .Person import Person
from .PlaceFrame import PlaceFrame
from .PersonFrame import PersonFrame


class Results:
    def __init__(self, config: dict) -> None:
        self.people_name = "people"
        self.places_name = "places"
        self.results_name = "results"
        self.config_name = "config"
        self.output_name = "output"
        self.log_name = "app.log"

        self.config = config

        self.log = False
        self.save_log = False
        self.save_config = True
        self.save_csv = True
        self.save_json = True
        self.return_output = True

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
        cwd = os.getcwd()
        now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")
        folder = "results"
        self.path = os.path.join(cwd, folder, now)
        if "directory" in self.config["options"]:
            directory = self.config["options"]["directory"]
            if directory is not None:
                self.path = os.path.join(cwd, folder, directory, now)

    def mkdir(self) -> None:
        os.makedirs(self.path)

    def setup_log(self) -> None:
        if self.save_log:
            logging.basicConfig(
                filename=os.path.join(self.path, self.log_name),
                filemode="w",
                format="%(message)s",
                level=logging.INFO,
            )
        elif self.log:
            logging.basicConfig(format="%(message)s", level=logging.INFO)
        else:
            logging.disable(logging.INFO)

    def open_people_csv(self) -> None:
        self.people_csv = open(os.path.join(self.path, self.people_name + ".csv"), "a")
        self.people_csv.write(PersonFrame.get_header())

    def close_people_csv(self) -> None:
        self.people_csv.close()

    def open_places_csv(self) -> None:
        self.places_csv = open(os.path.join(self.path, self.places_name + ".csv"), "a")
        self.places_csv.write(PlaceFrame.get_header())

    def close_places_csv(self) -> None:
        self.places_csv.close()

    def open_json(self) -> None:
        self.output_json = open(
            os.path.join(self.path, self.output_name + ".json"), "w"
        )

    def write_json(self) -> None:
        json.dump(self.output, self.output_json)

    def close_json(self) -> None:
        self.output_json.close()

    def init_results(self) -> None:
        self.output = {}
        self.results = dict.fromkeys([self.people_name, self.places_name], {})
        self.results[self.people_name] = dict.fromkeys(PersonFrame.header)
        self.results[self.places_name] = dict.fromkeys(PlaceFrame.header)

        self.output[self.config_name] = self.config
        self.output[self.results_name] = self.results

        for key in PersonFrame.header:
            self.results[self.people_name][key] = []
        for key in PlaceFrame.header:
            self.results[self.places_name][key] = []

    def write_person(self, person: Person) -> None:
        if self.save_csv:
            self.people_csv.write(person.get_data())
        if self.save_json or self.return_output:
            for key, value in person.store.items():
                self.results[self.people_name][key].append(value)

    def write_place(self, place: Place) -> None:
        if self.save_csv:
            self.places_csv.write(place.get_data())
        if self.save_json or self.return_output:
            for key, value in place.store.items():
                self.results[self.places_name][key].append(value)

    def write_config(self) -> None:
        with open(os.path.join(self.path, self.config_name + ".json"), "w") as f:
            json.dump(self.config, f)

    def done(self) -> None:
        if self.save_csv:
            self.close_people_csv()
            self.close_places_csv()
        if self.save_json:
            self.write_json()
            self.close_json()
        if self.return_output:
            return self.output

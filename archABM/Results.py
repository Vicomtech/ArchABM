import os
import datetime
import json
import logging
import numpy as np
from .PlaceFrame import PlaceFrame
from .PersonFrame import PersonFrame


class Results:
    def __init__(self, config):
        self.people_name = "people.csv"
        self.places_name = "places.csv"
        self.config_name = "config.json"
        self.log_name = "app.log"

        self.config = config
        self.mkpath()
        self.mkdir()

        self.setup_log()
        self.save_config(config)
        self.open_people()
        self.open_places()

    def mkpath(self):
        cwd = os.getcwd()
        now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")
        self.path = os.path.join(cwd, "results", now)
        p = self.config["Options"].replace({np.nan: None}).set_index("option")["value"].to_dict()
        if p["directory"] is not None:
            self.path = os.path.join(cwd, "results", p["directory"], now)

    def mkdir(self):
        os.makedirs(self.path)

    def setup_log(self):
        logging.basicConfig(
            filename=os.path.join(self.path, self.log_name), filemode="w", format="%(message)s", level=logging.INFO,
        )

    def open_people(self):
        self.people_file = open(os.path.join(self.path, self.people_name), "a")
        self.people_file.write(PersonFrame.get_header())

    def add_person(self, person):
        self.people_file.write(person.get_data())

    def close_people(self):
        self.people_file.close()

    def open_places(self):
        self.places_file = open(os.path.join(self.path, self.places_name), "a")
        self.places_file.write(PlaceFrame.get_header())

    def add_place(self, place):
        self.places_file.write(place.get_data())

    def close_places(self):
        self.places_file.close()

    def save_config(self, config):
        config_dict = {key: config[key].replace({np.nan: None}).to_dict(orient="records") for key in config.keys()}
        with open(os.path.join(self.path, self.config_name), "w") as f:
            json.dump(config_dict, f)

    def close(self):
        self.close_people()
        self.close_places()

from random import randrange

from simpy import Environment

from .Database import Database
from .Parameters import Parameters
from .SnapshotPlace import SnapshotPlace


class Place:
    id = -1

    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.next()
        self.id = Place.id

        self.env = env
        self.db = db
        self.params = params
        # self.convert_params()

        self.people = []
        self.num_people = 0
        self.infective_people = 0

        self.CO2_baseline = self.db.model.params.CO2_background
        self.CO2_level = self.CO2_baseline
        self.elapsed = 0.0
        self.infection_risk = 0.0
        self.last_updated = 0

        self.event = self.get_event()
        self.snapshot = SnapshotPlace()

    @classmethod
    def reset(cls) -> None:
        Place.id = -1

    @staticmethod
    def next() -> None:
        Place.id += 1

    def get_event(self) -> None:
        for e in self.db.events:
            if e.params.activity == self.params.activity:
                return e
        return None

    def add_person(self, person):
        # update air quality
        self.update_air()

        # add to list
        self.people.append(person)
        self.num_people += 1
        self.infective_people += person.status

        # save frame
        self.save_place_frame()

    def remove_person(self, person) -> None:
        # update air quality
        self.update_air()

        # remove from list
        self.people.remove(person)
        self.num_people -= 1
        self.infective_people -= person.status

        # save frame
        self.save_place_frame()

    def update_air(self) -> None:
        elapsed = self.env.now - self.last_updated
        if self.event.params.shared and elapsed > 0:
            inputs = Parameters(
                {
                    "room_area": self.params.area,
                    "room_height": self.params.height,
                    "room_ventilation_rate": self.params.ventilation,
                    "mask_efficiency": self.event.params.mask_efficiency,
                    "event_duration": elapsed / 60,
                    "num_people": self.num_people,
                    "infective_people": self.infective_people,
                    "CO2_level": self.CO2_level,
                }
            )
            CO2_level, infection_risk = self.db.model.get_risk(inputs)

            # update place
            self.CO2_level = CO2_level
            self.elapsed += elapsed
            self.infection_risk += elapsed * (infection_risk - self.infection_risk) / self.elapsed

            # update people # TODO: review if we need to update the risk of infected people as well
            for p in self.people:
                p.update(elapsed, infection_risk, CO2_level)
        self.last_updated = self.env.now

    def people_attending(self) -> int:
        if self.full():
            return 0
        return randrange(int(self.params.capacity - self.num_people))

    def full(self) -> bool:
        return self.params.capacity == self.num_people

    def save_place_frame(self) -> None:
        self.snapshot.set("run", self.db.run)
        self.snapshot.set("time", self.env.now, 0)
        self.snapshot.set("place", self.id)
        self.snapshot.set("num_people", self.num_people)
        self.snapshot.set("CO2_level", self.CO2_level, 2)
        self.snapshot.set("infection_risk", self.infection_risk, 4)
        self.db.results.write_place(self.snapshot)

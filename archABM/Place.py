import random

from simpy import Environment
from .PropagationModel import PropagationModel
from .Database import Database
from .Parameters import Parameters
from .PlaceFrame import PlaceFrame

class Place:
    id = -1

    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.next()
        self.id = Place.id

        self.env = env
        self.db = db
        self.params = params
        self.convert_params()

        self.people = []
        self.num_people = 0
        self.infective_people = 0
        self.times = {}

        self.CO2_baseline = self.db.model.params.CO2_background
        self.CO2_level = self.CO2_baseline
        self.elapsed = 0.0
        self.infection_risk = 0.0
        self.last_updated = 0

        self.event = self.get_event()
        # self.init_propagation_model()
        # self.aerosol_model = self.db.model
        self.place_frame = PlaceFrame()

    @classmethod
    def reset(cls) -> None:
        Place.id = -1

    def next(self) -> None:
        Place.id += 1

    # def init_propagation_model(self) -> None:
    #     if self.event.params.shared:

    #         self.propagation_model = PropagationModel()

    #         total_mask_efficiency = self.event.params.mask_efficiency
    #         room_ventilation_rate = self.params.ventilation
    #         room_area = self.params.area
    #         room_height = self.params.height
    #         self.propagation_model.start(total_mask_efficiency, room_ventilation_rate, room_area, room_height)

    def convert_params(self) -> None:
        # if self.params.department is not None:
        #     if "," in self.params.department:
        #         self.params.department = self.params.department.split(",")
        #     else:
        #         self.params.department = [self.params.department]
        if self.params.capacity is not None:
            self.params.capacity = int(self.params.capacity)
        else:
            self.params.capacity = 1000 # TODO: setup maximum capacity DONE

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
        # print("PLACE ADD", self.id, self.num_people)

        # register time
        if person not in self.times:
            self.times[person.id] = {}
        self.times[person.id]["t1"] = self.env.now

        # save frame
        self.save_place_frame()

    def remove_person(self, person) -> None:
        # register time
        self.times[person.id]["t2"] = self.env.now
        elapsed = self.times[person.id]["t2"] - self.times[person.id]["t1"]

        # update air quality
        self.update_air()
        self.times.pop(person.id, None)

        # remove from list
        self.people.remove(person)
        self.num_people -= 1
        self.infective_people -= person.status
        # print("PLACE DEL", self.id, self.num_people)

        # save frame
        self.save_place_frame()

    def update_air(self) -> None:
        elapsed = self.env.now - self.last_updated
        if self.event.params.shared and elapsed > 0:
            inputs = Parameters({
                "room_area": self.params.area,
                "room_height": self.params.height,
                "room_ventilation_rate": self.params.ventilation,
                "mask_efficiency": self.event.params.mask_efficiency,
                "event_duration": elapsed / 60,
                "num_people": self.num_people,
                "infective_people": self.infective_people,
                "CO2_level": self.CO2_level
            })
            CO2_level, infection_risk = self.db.model.get_risk(inputs)

            # UPDATE PLACE
            self.CO2_level = CO2_level
            self.elapsed += elapsed
            self.infection_risk += elapsed * (infection_risk - self.infection_risk) / self.elapsed

            # UPDATE PEOPLE
            for p in self.people:
                p.update(elapsed, infection_risk, CO2_level)
        self.last_updated = self.env.now

    def people_attending(self) -> int:
        if self.full():
            return 0
        # print("ATTENDING", self.params.name, self.params.capacity, self.num_people)
        return random.randrange(int(self.params.capacity - self.num_people))

    def full(self) -> bool:
        return self.params.capacity == self.num_people

    def save_place_frame(self) -> None:
        # self.place_frame.reset()
        self.place_frame.set("run", self.db.run)
        self.place_frame.set("time", self.env.now, 0)
        self.place_frame.set("place", self.id)
        self.place_frame.set("num_people", self.num_people)
        self.place_frame.set("CO2_level", self.CO2_level, 2)
        self.place_frame.set("infection_risk", self.infection_risk, 4)
        self.db.results.write_place(self.place_frame)

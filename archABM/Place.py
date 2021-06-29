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
        self.times = {}

        self.air_quality_baseline = self.db.model.params.background_co2 # 100.0 TODO: review
        self.air_quality = self.air_quality_baseline
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
        # print("PLACE DEL", self.id, self.num_people)

        # save frame
        self.save_place_frame()

    def update_air(self) -> None:
        elapsed = self.env.now - self.last_updated
        if self.event.params.shared and elapsed > 0:
            num_people = self.num_people
            ratio_ventilation = 0.05
            ratio_pollution = 0.05

            # (dosis_six_hours, dosis_infectious, individual_infection_risk, risk_one_person,) = self.propagation_model.get_risk(
            #     num_people,
            #     # self.db.options.params.mask_efficiency,  # TODO: change this with self.event.params.mask_efficiency DONE
            #     self.event.params.mask_efficiency,
            #     self.db.options.params.room_ventilation,
            #     self.params.area,
            #     self.params.height,
            #     elapsed / 60,
            #     # self.air_quality # TODO: take into account previous air quality
            # )
            susceptible_people = num_people
            time_in_room_h = elapsed / 60
            # (dosis_six_hours, dosis_infectious, individual_infection_risk, risk_one_person,) = self.propagation_model.get_risk_optimized(susceptible_people, time_in_room_h)
            inputs = Parameters({
                "room_area": self.params.area,
                "room_height": self.params.height,
                "room_ventilation_rate": self.params.ventilation,
                "mask_efficiency": self.event.params.mask_efficiency,
                "time_in_room_h": time_in_room_h,
                "susceptible_people": susceptible_people
            })


    #         total_mask_efficiency = self.event.params.mask_efficiency
    #         room_ventilation_rate = self.params.ventilation
    #         room_height = self.params.height
            place_risk, person_risk = self.db.model.get_risk(inputs)
            if self.id == 1:
                print(place_risk, person_risk, self.air_quality)
            # if elapsed > 0:
            #     print(
            #         "AIR: ", num_people, round(elapsed), dosis_infectious, risk_one_person
            #     )
            for p in self.people:
                # p.update_risk(risk_one_person)
                p.update_risk(person_risk)
            if num_people > 0:
                self.air_quality += place_risk
                # self.air_quality -= dosis_infectious
                # self.air_quality -= ratio_pollution * num_people * elapsed
            else:
                self.air_quality -= 3* self.params.ventilation * elapsed # TODO: https://www.researchgate.net/publication/221932157_Ventilation_Efficiency_and_Carbon_Dioxide_CO2_Concentration
            # TODO: saturate air quality based on CO2?  
            # self.air_quality = min(100, max(0, self.air_quality))
            self.air_quality = max(self.air_quality_baseline, self.air_quality)

            # print(self.id, elapsed, num_people, self.air_quality)
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
        self.place_frame.set("air_quality", self.air_quality, 2)
        self.db.results.write_place(self.place_frame)

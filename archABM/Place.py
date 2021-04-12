import random
from .PlaceFrame import PlaceFrame
from .PropagationModel import PropagationModel


class Place:
    id = -1

    def __init__(self, env, db, params):
        self.next()
        self.id = Place.id

        self.env = env
        self.db = db
        self.params = params
        self.convert_params()

        self.people = []
        self.num_people = 0
        self.times = {}

        self.air_quality = 100
        self.last_updated = 0
        self.propagation_model = PropagationModel()

        self.event = self.get_event()

        self.place_frame = PlaceFrame()

    @classmethod
    def reset(cls):
        Place.id = -1

    def next(self):
        Place.id += 1

    def convert_params(self):
        if self.params.department is not None:
            if "," in self.params.department:
                self.params.department = self.params.department.split(",")
            else:
                self.params.department = [self.params.department]
        if self.params.capacity is not None:
            self.params.capacity = int(self.params.capacity)
        else:
            self.params.capacity = 1000

    def get_event(self):
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

    def remove_person(self, person):
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

    def update_air(self):
        if self.event.params.shared:
            elapsed = self.env.now - self.last_updated
            num_people = len(self.times)
            ratio_ventilation = 0.05
            ratio_pollution = 0.05

            (
                dosis_six_hours,
                dosis_infectious,
                individual_infection_risk,
                risk_one_person,
            ) = self.propagation_model.get_risk(
                num_people,
                # self.db.options.params.mask_efficiency,  # TODO: change this with self.event.params.mask_efficiency DONE
                self.event.params.mask_efficiency,
                self.db.options.params.room_ventilation,
                self.params.area,
                self.params.height,
                elapsed / 60,
                # self.air_quality # TODO: take into account previous air quality
            )

            # if elapsed > 0:
            #     print(
            #         "AIR: ", num_people, round(elapsed), dosis_infectious, risk_one_person
            #     )
            for p in self.people:
                p.update_risk(risk_one_person)
            if num_people > 0:
                self.air_quality -= dosis_infectious
                # self.air_quality -= ratio_pollution * num_people * elapsed
            else:
                self.air_quality += ratio_ventilation * elapsed
            # TODO: saturate air quality DONE
            self.air_quality = min(100, max(0, self.air_quality))

            # print(self.id, elapsed, num_people, self.air_quality)
        self.last_updated = self.env.now

    def people_attending(self):
        if self.full():
            return 0
        # print("ATTENDING", self.params.name, self.params.capacity, self.num_people)
        return random.randrange(self.params.capacity - self.num_people)

    def full(self):
        return self.params.capacity == self.num_people

    def save_place_frame(self):
        self.place_frame.set("time", self.env.now, 0)
        self.place_frame.set("place", self.id)
        # self.place_frame.set("people", self.people)
        self.place_frame.set("num_people", self.num_people)
        self.place_frame.set("air_quality", self.air_quality, 0)
        self.db.results.add_place(self.place_frame)

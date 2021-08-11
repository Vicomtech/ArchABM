from random import randrange
from simpy import Environment

from .database import Database
from .parameters import Parameters
from .snapshot_place import SnapshotPlace


class Place:
    """Place primitive"""

    id: int = -1

    def __init__(self, env: Environment, db: Database, params: Parameters) -> None:
        self.next()
        self.id = Place.id

        self.env = env
        self.db = db
        self.params = params

        self.people = []
        self.num_people = 0
        self.infective_people = 0

        self.CO2_baseline = self.db.model.params.CO2_background
        self.CO2_level = self.CO2_baseline
        self.quanta_level = 0.0

        self.elapsed = 0.0
        self.last_updated = 0.0

        self.event = self.get_event()
        self.snapshot = SnapshotPlace()

    @classmethod
    def reset(cls) -> None:
        """Resets :class:`~archABM.place.Place` ID."""
        Place.id = -1

    @staticmethod
    def next() -> None:
        """Increments one unit the :class:`~archABM.place.Place` ID."""
        Place.id += 1

    def get_event(self) -> None:
        """Yields the corresponding :class:`~archABM.event_model.EventModel`

        Returns:
            EventModel: place's type of activity
        """
        for e in self.db.events:
            if e.params.activity == self.params.activity:
                return e
        return None

    def add_person(self, person):
        """Add person to place

        Prior to the inclusion of the person, the ``air quality`` of the place is updated. 
        Then, the number of people in the place is incremented by one unit, 
        and the number of infective people is updated in case the entering person's status is ``infective``.
        Finally, a ``snapshot`` is taken and saved into the simulation history.

        Args:
            person (Person): person to be added
        """
        # update air quality
        self.update_air()

        # add to list
        self.people.append(person)
        self.num_people += 1
        self.infective_people += person.status

        # save snapshot
        self.save_snapshot()

    def remove_person(self, person) -> None:
        """Remove person from place

        Prior to the exclusion of the person, the ``air quality`` of the place is updated. 
        Then, the number of people in the place is decremented by one unit, 
        and the number of infective people is updated in case the leaving person's status is ``infective``.
        Finally, a ``snapshot`` is taken and saved into the simulation history.

        Args:
            person (Person): person to be removed
        """
        # update air quality
        self.update_air()

        # remove from list
        self.people.remove(person)
        self.num_people -= 1
        self.infective_people -= person.status

        # save snapshot
        self.save_snapshot()

    def update_place(self):
        """Update place air quality

        Updates the ``air quality`` of the place and saves a ``snapshot`` into the simulation history.
        """
        # update air quality
        self.update_air()

        # save snapshot
        self.save_snapshot()

    def update_air(self) -> None:
        """Air quality update

        This method updates the air quality based on the selected :class:`~archABM.aerosol_model.AerosolModel`.

        The infection risk is also computed by the aerosol model, 
        and is transferred to every person in the room.
        
        """
        elapsed = self.env.now - self.last_updated
        if self.event.params.shared and elapsed > 0:
            inputs = Parameters(
                {
                    "room_area": self.params.area,
                    "room_height": self.params.height,
                    "room_ventilation_rate": self.params.ventilation,
                    "recirculated_flow_rate": self.params.recirculated_flow_rate,
                    "mask_efficiency": self.event.params.mask_efficiency,
                    "event_duration": elapsed / 60,
                    "num_people": self.num_people,
                    "infective_people": self.infective_people,
                    "CO2_level": self.CO2_level,
                    "quanta_level": self.quanta_level,
                }
            )
            CO2_level, quanta_inhaled, quanta_level = self.db.model.get_risk(inputs)

            # update place
            self.CO2_level = CO2_level
            self.quanta_level = quanta_level

            # self.elapsed += elapsed
            # self.infection_risk_avg += elapsed * (infection_risk - self.infection_risk_avg) / self.elapsed
            # self.infection_risk_cum += infection_risk

            # update people # TODO: review if we need to update the risk of infected people as well
            for p in self.people:
                p.update(elapsed, quanta_inhaled, CO2_level)
        self.last_updated = self.env.now

    def people_attending(self) -> int:
        """Number of people attending a collective event

        .. note::
            If the place is full, this method yields ``0`` people.

        Returns:
            int: number of people
        """
        if self.full():
            return 0
        return randrange(int(self.params.capacity - self.num_people))

    def full(self) -> bool:
        """Checks whether the place is full ``num_people < capacity``

        Returns:
            bool: place is full
        """
        return self.params.capacity == self.num_people

    def save_snapshot(self) -> None:
        """Saves state snapshot on :class:`~archABM.snapshot_place.SnapshotPlace`"""
        self.snapshot.set("run", self.db.run)
        self.snapshot.set("time", self.env.now, 0)
        self.snapshot.set("place", self.id)
        self.snapshot.set("num_people", self.num_people)
        self.snapshot.set("infective_people", self.infective_people)
        self.snapshot.set("CO2_level", self.CO2_level, 2)
        self.snapshot.set("quanta_level", self.quanta_level, 6)
        self.db.results.write_place(self.snapshot)

from random import sample
from typing import List

from simpy import Environment

from .actions import Actions
from .database import Database
from .event_model import EventModel
from .options import Options
from .parameters import Parameters
from .person import Person
from .place import Place


class Creator:
    """Initializes the required assets to run a simulation:
        :class:`~archABM.options.Options`, 
        :class:`~archABM.aerosol_model.AerosolModel`,
        :class:`~archABM.event.Event`, 
        :class:`~archABM.place.Place`, 
        :class:`~archABM.actions.Actions`, 
        :class:`~archABM.person.Person`.
    """

    env: Environment
    config: dict
    db: Database

    def __init__(self, env: Environment, config: dict, db: Database) -> None:
        self.env = env
        self.config = config
        self.db = db

        Person.reset()
        Place.reset()
        EventModel.reset()

    def create_options(self) -> Options:
        """Initializes general :class:`~archABM.options.Options` for the simulation.

        Returns:
            Options: general :class:`~archABM.options.Options` for the simulation
        """
        p = self.config["options"]
        params = Parameters(p)
        options = Options(self.env, self.db, params)

        return options

    def create_events(self) -> List[EventModel]:
        """Initializes list of :class:`~archABM.event_model.EventModel` and their respective :class:`~archABM.parameters.Parameters`.

        Returns:
            List[EventModel]: types of events or activities
        """
        events = []
        for e in self.config["events"]:
            params = Parameters(e)
            event = EventModel(params)
            events.append(event)

        return events

    def create_places(self) -> List[Place]:
        """Initializes list of :class:`~archABM.place.Place` and their respective :class:`~archABM.parameters.Parameters`.

        Returns:
            List[Place]: list of available places
        """
        places = []
        for p in self.config["places"]:
            params = Parameters(p)
            place = Place(self.env, self.db, params)
            places.append(place)

        return places

    def create_actions(self) -> Actions:
        """Initializes instance of class :class:`~archABM.actions.Actions`.

        Returns:
            Actions: instance of class :class:`~archABM.actions.Actions`
        """
        return Actions(self.env, self.db)

    def create_people(self) -> List[Person]:
        """Initializes list of :class:`~archABM.person.Person` and their respective :class:`~archABM.parameters.Parameters`.

        It also sets the status of certain :class:`~archABM.person.Person` from ``susceptible`` to ``infected``.
        This is controlled by the ``ratio_infected`` configuration parameter.

        Returns:
            List[Person]: simulation people
        """
        people = []
        for p in self.config["people"]:
            params = Parameters(p)
            person = Person(self.env, self.db, params)
            person.start()
            people.append(person)

        num_people = len(people)
        num_infected = int(max(1, self.config["options"]["ratio_infected"] * num_people))
        for p in sample(people, num_infected):
            p.status = 1

        return people

    def create_model(self):
        """Initializes the selected COVID19 aerosol model.

        At the moment, there are three models available:

        #. :class:`~archABM.aerosol_model_colorado.AerosolModelColorado`: COVID-19 Airborne Transmission Estimator \
            :cite:`doi:10.1021/acs.estlett.1c00183,https://doi.org/10.1111/ina.12751,Peng2021.04.21.21255898`

        #. :class:`~archABM.aerosol_model_mit.AerosolModelMIT`: MIT COVID-19 Indoor Safety Guideline \
            :cite:`Bazante2018995118,Bazant2021.04.04.21254903,Risbeck2021.06.21.21259287`
            
        #. :class:`~archABM.aerosol_model_maxplanck.AerosolModelMaxPlanck`: Model Calculations of Aerosol Transmission and \
            Infection Risk of COVID-19 in Indoor Environments :cite:`ijerph17218114`
        
        Returns:
            AerosolModel: selected aerosol model
        """
        options = self.config["options"]
        selection = options["model"]
        params = Parameters(options["model_parameters"][selection])
        model = None
        if selection == "MaxPlanck":
            from .aerosol_model_maxplanck import AerosolModelMaxPlanck

            model = AerosolModelMaxPlanck(params)
        elif selection == "MIT":
            from .aerosol_model_mit import AerosolModelMIT

            model = AerosolModelMIT(params)
        elif selection == "Colorado":
            from .aerosol_model_colorado import AerosolModelColorado

            model = AerosolModelColorado(params)

        return model

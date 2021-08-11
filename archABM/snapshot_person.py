from .snapshot import Snapshot


class SnapshotPerson(Snapshot):
    """Stores the state of a person at a given time

    It saves the following attributes:

    .. list-table:: 
        :header-rows: 1

        * - Attribute
          - Description
          - Type
        * - *run*
          - Simulation run
          - :obj:`int`
        * - *time*
          - Simulation time (minutes)
          - :obj:`int`
        * - *person*
          - Person ID
          - :obj:`int`
        * - *status*
          - Person status (0: susceptible, 1: infective)
          - :obj:`bool`
        * - *place*
          -  Place ID
          - :obj:`int`
        * - *event*
          - Event ID
          - :obj:`int`
        * - *CO2_level*
          - Average CO\ :sub:`2` level (ppm)
          - :obj:`float`
        * - *quanta_inhaled*
          - Quanta inhaled (quanta)
          - :obj:`float`
    """

    header = ["run", "time", "person", "status", "place", "event", "CO2_level", "quanta_inhaled"]

    def __init__(self) -> None:
        super(SnapshotPerson, self).__init__(SnapshotPerson.header)

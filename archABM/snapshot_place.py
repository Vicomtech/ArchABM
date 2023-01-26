from .snapshot import Snapshot


class SnapshotPlace(Snapshot):
    """Stores the state of a place at a given time

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
        * - *place*
          -  Place ID
          - :obj:`int`
        * - *activity*
          -  Activity
          - :obj:`str`
        * - *num_people*
          - Number of people
          - :obj:`int`
        * - *infective_people*
          - Number of infective people
          - :obj:`int`
        * - *CO2_level*
          - CO\ :sub:`2` level (ppm)
          - :obj:`float`
        * - *quanta_level*
          - quanta level (ppm)
          - :obj:`float`
        * - *temperature*
          - Room temperature
          - :obj:`float`
        * - *relative_humidity*
          - Room relative humidity
          - :obj:`float`
    """

    header = ["run", "time", "place", "activity", "num_people", "infective_people", "CO2_level", "quanta_level", "temperature", "relative_humidity"]

    def __init__(self) -> None:
        super(SnapshotPlace, self).__init__(SnapshotPlace.header)

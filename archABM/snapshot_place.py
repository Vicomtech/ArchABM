from .snapshot import Snapshot


class SnapshotPlace(Snapshot):
    """Stores the state of a place at a given time

    It saves the following attributes:

    .. list-table:: 
        :header-rows: 1

        * - Attribute
          - Description
          - Type
        * - "run"
          - Simulation run
          - :obj:`int`
        * - "time"
          - Simulation time (minutes)
          - :obj:`int`
        * - "place"
          -  Place ID
          - :obj:`int`
        * - "num_people"
          - Number of people
          - :obj:`int`
        * - "CO2_level"
          - CO\ :sub:`2` level (ppm)
          - :obj:`float`
        * - "infection_risk"
          - Average probability of infection
          - :obj:`float`
    """
    header = ["run", "time", "place", "num_people", "CO2_level", "infection_risk"]

    def __init__(self) -> None:
        super(SnapshotPlace, self).__init__(SnapshotPlace.header)

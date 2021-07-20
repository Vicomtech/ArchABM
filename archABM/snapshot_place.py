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
        * - "infection_risk_cum"
          - Probability of infection (cumulative)
          - :obj:`float`
        * - "infection_risk_avg"
          - Probability of infection (average)
          - :obj:`float`
    """
    header = ["run", "time", "place", "num_people", "infective_people", "CO2_level", "quanta_level"]

    def __init__(self) -> None:
        super(SnapshotPlace, self).__init__(SnapshotPlace.header)

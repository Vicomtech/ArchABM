from .snapshot import Snapshot


class SnapshotPlace(Snapshot):
    header = ["run", "time", "place", "num_people", "CO2_level", "infection_risk"]

    def __init__(self) -> None:
        super(SnapshotPlace, self).__init__(SnapshotPlace.header)

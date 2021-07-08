from .Snapshot import Snapshot


class SnapshotPerson(Snapshot):
    header = ["run", "time", "person", "status", "place", "event", "CO2_level", "infection_risk"]

    def __init__(self) -> None:
        super(SnapshotPerson, self).__init__(SnapshotPerson.header)

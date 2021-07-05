class PlaceFrame:
    header = ["run", "time", "place", "num_people", "CO2_level", "infection_risk"]

    def __init__(self) -> None:
        self.reset()

    def reset(self) -> None:
        self.store = dict.fromkeys(PlaceFrame.header, "")

    @staticmethod
    def get_header() -> str:
        return ",".join(PlaceFrame.header) + "\n"

    def get_data(self) -> str:
        return ",".join(map(str, self.store.values())) + "\n"

    def set(self, key: str, value, digits: int = 2):
        if key in PlaceFrame.header:
            typ = type(value)
            if typ == bool:
                value = int(value)
            elif typ == int:
                pass
            elif typ == float:
                if digits == 0:
                    value = int(value)
                else:
                    value = round(value, digits)
            elif typ == list:
                value = ";".join(map(str, value))
            self.store[key] = value
        else:
            raise BaseException

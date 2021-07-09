class Snapshot:
    """This class helps in the storage of an agent's state at a given time
    """
    header: list
    store: dict

    def __init__(self, header) -> None:
        self.header = header
        self.store = {}
        self.reset()

    def reset(self) -> None:
        self.store = dict.fromkeys(self.header, "")

    @classmethod
    def get_header(cls) -> str:
        return ",".join(cls.header) + "\n"

    def get_data(self) -> str:
        return ",".join(map(str, self.store.values())) + "\n"

    def set(self, key: str, value, digits: int = 2) -> None:
        if key in self.header:
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

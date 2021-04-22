class PersonFrame:
    header = ["run", "time", "person", "place", "event", "risk"]

    def __init__(self):
        self.reset()

    def reset(self):
        self.store = dict.fromkeys(PersonFrame.header, "")

    @staticmethod
    def get_header():
        return ",".join(PersonFrame.header) + "\n"

    def get_data(self):
        return ",".join(map(str, self.store.values())) + "\n"

    def set(self, key, value, digits=2):
        if key in PersonFrame.header:
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


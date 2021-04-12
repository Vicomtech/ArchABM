class PersonFrame:
    header = ["time", "person", "place", "activity", "status", "risk"]

    def __init__(self):
        self.store = dict.fromkeys(PersonFrame.header, "")

    @staticmethod
    def get_header():
        return ",".join(PersonFrame.header) + "\n"

    def get_data(self):
        return ",".join(map(str, self.store.values())) + "\n"

    def set(self, key, value, digits=2):
        if key in self.store.keys():
            if isinstance(value, bool):
                value = int(value)
                value = str(value)
            elif isinstance(value, int):
                value = str(value)
            elif isinstance(value, float):
                if digits == 0:
                    value = int(value)
                else:
                    value = round(value, digits)
                value = str(value)
            elif isinstance(value, list):
                value = ";".join(map(str, value))
            self.store[key] = value
        else:
            raise BaseException

from typing import Generator


class Parameters:
    def __init__(self, __dict__: dict = None) -> None:
        if __dict__ is not None:
            self.__dict__ = __dict__

    def __repr__(self) -> str:
        return str(self.__dict__)

    def __iter__(self) -> Generator[str, None, None]:
        for key, value in self.__dict__.items():
            yield key, value

    def __copy__(self):
        newone = type(self)()
        newone.__dict__.update(self.__dict__)
        return newone

    def copy(self):
        newone = type(self)()
        newone.__dict__.update(self.__dict__)
        return newone

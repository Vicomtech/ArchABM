from typing import Generator


class Parameters:
    """Helper to access dictionary elements as class attributes 
    """

    __dict__: dict

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
        """Return a shallow copy of the instance.

        Returns:
            Parameters: cloned object
        """
        newone = type(self)()
        newone.__dict__.update(self.__dict__)
        return newone

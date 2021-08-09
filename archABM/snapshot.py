class Snapshot:
    """Stores the state of an agent at a given time
    """

    header: list
    store: dict

    def __init__(self, header) -> None:
        self.header = header
        self.store = {}
        self.reset()

    def reset(self) -> None:
        """Initializes dictionary :attr:`store` with :attr:`header` as keys."""
        self.store = dict.fromkeys(self.header, "")

    @classmethod
    def get_header(cls, sep=",") -> str:
        """Takes all items in :attr:`header` and joins them into one string.
                
        A string must be specified as the separator, by default "," 

        Args:
            sep (str, optional): separator. Defaults to ",".

        Returns:
            str: a string created by joining the elements of :attr:`header` by string separator
        """
        return sep.join(cls.header) + "\n"

    def get_data(self, sep=",") -> str:
        """Takes all items in :attr:`store` and joins them into one string.
                
        A string must be specified as the separator, by default "," 

        Args:
            sep (str, optional): separator. Defaults to ",".

        Returns:
            str: a string created by joining the elements of :attr:`store` by string separator
        """
        return sep.join(map(str, self.store.values())) + "\n"

    def set(self, key: str, value, digits: int = 2) -> None:
        """Add a key:value pair to the :attr:`store` dictionary

        * If :attr:`value` is :obj:`bool`, it is casted to :obj:`int`. 
        * If :attr:`value` is :obj:`list`, the elements are joined into one :obj:`str`, separated by ";". 
        * If :attr:`value` is :obj:`float`, it is rounded to the specified number :attr:`digits`. 
        * If :attr:`digits` is :const:`0`, :attr:`value` is casted to :obj:`int`.

        Args:
            key (str): item key 
            value (Union[bool, int, float, list]): item value
            digits (int, optional): number of digits to store. Defaults to 2.

        Raises:
            BaseException: raises if the specified :attr:`key` is not a key in :attr:`store`
        """
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

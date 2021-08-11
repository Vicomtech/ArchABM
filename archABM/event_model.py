import copy
import random
from .parameters import Parameters


class EventModel:
    """Defines an event model, also called "activity"

    An event model is defined by these parameters:
    
    * Activity name: :obj:`str`
    * Schedule: :obj:`list` of :obj:`tuple` (in minutes :obj:`int`)
    * Repetitions range: minimum (:obj:`int`) and maximum (:obj:`int`)
    * Duration range: minimum (:obj:`int`) and maximum (:obj:`int`) in minutes
    * Other parameters: 

        * mask efficiency ratio: :obj:`float`
        * collective event: :obj:`bool`
        * shared event: :obj:`bool`

    The schedule defines the allowed periods of time in which an activity can happen.
    For example, ``schedule=[(120,180),(240,300)]`` allows people to carry out this activity from
    the time ``120`` to ``180`` and also from time ``240`` until ``300``. 
    Notice that the schedule units are in minutes.

    Each activity is limited to a certain duration, and its priority follows
    a piecewise linear function, parametrized by:

    * ``r``: repeat\ :sub:`min` 
    * ``R``: repeat\ :sub:`max`
    * ``e``: event count

    .. math::
        Priority(e) = 
        \\left\{\\begin{matrix}
        1-(1-\\alpha)\\cfrac{e}{r}\,,\quad 0 \leq  e < r \\\\
        \\alpha\\cfrac{R-e}{R-r}\,,\quad r \leq  e < R \\ 
        \end{matrix}\\right.



    .. tikz:: Priority piecewise linear function
        \pgfmathsetmacro{\\N}{10};
        \pgfmathsetmacro{\\M}{6};
        \pgfmathsetmacro{\\NN}{\\N-1};
        \pgfmathsetmacro{\\MM}{\\M-1};
        \pgfmathsetmacro{\\repmin}{2.25};
        \pgfmathsetmacro{\\repmax}{8.5};
        \pgfmathsetmacro{\\a}{2};
        \coordinate (A) at (0,\\MM);
        \coordinate (B) at (\\NN,0);
        \coordinate (C) at (\\repmin, \\a);
        \coordinate (D) at (\\repmax, 0);
        \coordinate (E) at (\\repmin, 0);
        \coordinate (F) at (0, \\a);
        \draw[stepx=1,thin, black!20] (0,0) grid (\\N,\\M);
        \draw[->, very thick] (0,0) to (\\N,0) node[right] {Event count};
        \draw[->, very thick] (0,0) to (0,\\M)  node[above] {Priority};
        \draw (0.1,0) -- (-0.1, 0) node[anchor=east] {0};
        \draw (0, 0.1) -- (0, -0.1);
        \draw (\\repmin,0.1) -- (\\repmin,-0.1) node[anchor=north] {$repeat_{min}$};
        \draw (\\repmax,0.1) -- (\\repmax,-0.1) node[anchor=north] {$repeat_{max}$};
        \draw[ultra thick] (0.1, \\MM) -- (-0.1, \\MM) node[left] {1};
        \draw[very thick, black!50, dashed] (C) -- (F) node[left] {$\\alpha$};
        \draw[very thick, black!50, dashed] (C) -- (E);
        \draw[ultra thick, red] (A) -- (C);
        \draw[ultra thick, red] (C) -- (D);
        :xscale: 80
        :align: left
     
    """

    id: int = -1
    params: Parameters
    count: int
    noise: int

    def __init__(self, params: Parameters) -> None:
        self.next()
        self.id = EventModel.id

        self.params = params
        self.count = 0
        self.noise = None

    @classmethod
    def reset(cls) -> None:
        """Resets :class:`~archABM.event_model.EventModel` ID."""
        EventModel.id = -1

    @staticmethod
    def next() -> None:
        """Increments one unit the :class:`~archABM.event_model.EventModel` ID."""
        EventModel.id += 1

    def get_noise(self) -> int:
        """Generates random noise

        Returns:
            int: noise amount in minutes
        """
        if self.noise is None:
            m = 15  # minutes # TODO: review hardcoded value
            if m == 0:
                self.noise = 0
            else:
                self.noise = random.randrange(m)  # minutes
        return self.noise

    def new(self):
        """Generates a :class:`~archABM.event_model.EventModel` copy, with reset count and noise

        Returns:
            EventModel: cloned instance
        """
        self.count = 0
        self.noise = None
        return copy.copy(self)

    def duration(self, now) -> int:
        """Generates a random duration between :attr:`duration_min` and :attr:`duration_max`.

        .. note::
            If the generated duration, together with the current timestamp, 
            exceeds the allowed schedule, the duration is limited to finish 
            at the scheduled time interval.
        

        The :attr:`noise` attribute is used to model the schedule's time tolerance.

        Args:
            now (int): current timestamp in minutes

        Returns:
            int: event duration in minutes
        """
        duration = random.randint(self.params.duration_min, self.params.duration_max)
        estimated = now + duration
        noise = self.get_noise()  # minutes
        for interval in self.params.schedule:
            a, b = interval
            if a - noise <= now <= b + noise < estimated:
                duration = b + noise - now + 1
                break
        return duration

    def priority(self) -> float:
        """Computes the priority of a certain event.

        The priority function follows a piecewise linear function, parametrized by:

        * ``r``: repeat\ :sub:`min` 
        * ``R``: repeat\ :sub:`max`
        * ``e``: event count

        .. math::
            Priority(e) = 
            \\left\{\\begin{matrix}
            1-(1-\\alpha)\\cfrac{e}{r}\,,\quad 0 \leq  e < r \\\\
            \\alpha\\cfrac{R-e}{R-r}\,,\quad r \leq  e < R \\ 
            \end{matrix}\\right.

        Returns:
            float: priority value [0-1]
        """
        alpha = 0.5  # TODO: review hardcoded value
        if self.params.repeat_max is None:
            return random.uniform(0.0, 1.0)
        if self.count == self.params.repeat_max:
            return 0.0
        if self.count < self.params.repeat_min:
            return 1 - (1 - alpha) * self.count / self.params.repeat_min
        if self.params.repeat_min == self.params.repeat_max:
            return alpha
        return alpha * (self.params.repeat_max - self.count) / (self.params.repeat_max - self.params.repeat_min)

    def probability(self, now: int) -> float:
        """Wrapper to call the priority function

        If the event :attr:`count` is equal to the :attr:`repeat_max` parameters,
        it yields a ``0`` probability. Otherwise, it computes the :meth:`priority` function
        described above.

        Args:
            now (int): current timestamp in minutes

        Returns:
            float: event probability [0-1]
        """
        p = 0.0
        if self.count == self.params.repeat_max:
            return p

        noise = self.get_noise()  # minutes
        for interval in self.params.schedule:
            a, b = interval
            if a - noise <= now <= b + noise:
                p = self.priority()
                break

        return p

    def valid(self) -> bool:
        """Computes whether the event count has reached the :attr:`repeat_max` limit.

        It yields ``True``
        if :attr:`repeat_max` is ``undefined`` or 
        if the event :attr:`count` is less than :attr:`repeat_max`. 
        Otherwise, it yields ``False``.

        Returns:
            bool: valid event
        """
        if self.params.repeat_max is None:
            return True
        return self.count < self.params.repeat_max

    def consume(self) -> None:
        """Increments one unit the event count"""
        self.count += 1
        # logging.info("Event %s repeated %d out of %d" % (self.name, self.count, self.target))

    def supply(self) -> None:
        """Decrements one unit the event count"""
        self.count -= 1

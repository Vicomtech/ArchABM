import copy
import random


class EventModel:
    id = -1

    def __init__(self, params) -> None:
        self.next()
        self.id = EventModel.id

        self.params = params
        self.count = 0
        self.noise = None

    @classmethod
    def reset(cls) -> None:
        EventModel.id = -1

    @staticmethod
    def next() -> None:
        EventModel.id += 1

    def get_noise(self) -> int:
        if self.noise is None:
            m = 15  # minutes # TODO: review hardcoded value
            if m == 0:
                self.noise = 0
            else:
                self.noise = random.randrange(m)  # minutes
        return self.noise

    def new(self):
        self.count = 0
        self.noise = None
        return copy.copy(self)

    def duration(self, now) -> int:
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

        # if self.target == 0:
        #     return 0.0
        # if self.count < self.params.repeat_min:
        #     return 1.0
        # return (self.target - self.count) / self.target

    def probability(self, now: int) -> float:
        p = 0.0
        # if self.count == self.target:
        #     return p
        # if self.params.repeat_max is not None:
        if self.count == self.params.repeat_max:
            return 0.0

        noise = self.get_noise()  # minutes
        for interval in self.params.schedule:
            a, b = interval
            if a - noise <= now <= b + noise:
                p = self.priority()
                break

        return p

    def valid(self) -> bool:
        if self.params.repeat_max is None:
            return True
        return self.count < self.params.repeat_max

    def consume(self) -> None:
        self.count += 1
        # logging.info("Event %s repeated %d out of %d" %
        # (self.name, self.count, self.target))

    def supply(self) -> None:
        self.count -= 1

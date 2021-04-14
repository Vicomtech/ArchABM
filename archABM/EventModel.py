import numpy as np
import ast
import copy
import logging
import random


class EventModel:
    def __init__(self, params):
        self.params = params
        # self.activity = activity
        # self.schedule = ast.literal_eval(schedule)  # hours
        # self.repeat_min = repeat_min
        # self.repeat_max = repeat_max
        # self.duration_min = duration_min  # minutes
        # self.duration_max = duration_max  # minutes

        # self.convert_schedule()
        self.reset()

        # self.count = 0
        self.noise = None

    def get_noise(self):
        if self.noise is None:
            m = 15  # minutes
            if m == 0:
                self.noise = 0
            else:
                self.noise = random.randrange(m)  # minutes
        return self.noise

    def convert_schedule(self):
        self.params.schedule = ast.literal_eval(self.params.schedule)  # hours
        self.params.schedule = [[s[0] * 60, s[1] * 60] for s in self.params.schedule]  # minutes

    def reset(self):
        # if self.params.repeat_max is None:
        #     self.params.repeat_max = 1000
        # if self.params.repeat_min == self.params.repeat_max:
        #     self.target = self.params.repeat_min
        # else:
        #     self.target = np.random.randint(
        #         self.params.repeat_min, self.params.repeat_max
        #     )
        self.count = 0

    def new(self):
        self.reset()
        return copy.copy(self)

    def duration(self, now):
        # duration = np.random.random_integers(
        #     self.params.duration_min, self.params.duration_max
        # )
        duration = random.randint(self.params.duration_min, self.params.duration_max)
        estimated = now + duration
        for interval in self.params.schedule:
            a, b = interval
            # if a <= now <= b and estimated > b:
            #     duration = b - now
            noise = self.get_noise()  # minutes
            if a - noise <= now <= b + noise and estimated > b + noise:
                duration = b + noise - now
                break
        return duration

    def priority(self):
        alpha = 0.5
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

    def probability(self, now):
        p = 0.0
        # if self.count == self.target:
        #     return p
        # if self.params.repeat_max is not None:
        if self.count == self.params.repeat_max:
            return 0.0

        for interval in self.params.schedule:
            a, b = interval
            noise = self.get_noise()  # minutes
            if a - noise <= now <= b + noise:
                p = self.priority()
                break

        return p

    def valid(self):
        if self.params.repeat_max is None:
            return True
        return self.count < self.params.repeat_max
        # return self.count < self.target

    def consume(self):
        self.count += 1
        # logging.info("Event %s repeated %d out of %d" %
        # (self.name, self.count, self.target))

    def supply(self):
        self.count -= 1

from archABM.engine import Engine
import pandas as pd
import numpy as np
import timeit
import random
import string
import json

def main(config):
    simulation = Engine(config)
    results = simulation.run()

# varying number of people and capacity
number_repetitions = 5
number_runs = 5
ratio_arr = [0.1, 0.5, 1, 2, 5, 10, 20, 40]
extra_places_arr = [0, 5, 10, 15, 20]
results = []
for i in range(number_repetitions):
    for ratio in ratio_arr:
        for extra_places in extra_places_arr:

            with open("experiments/config_performance.json", "r") as f:
                config = json.load(f)

            config["options"]["number_runs"] = number_runs

            for k in range(extra_places):
                name = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
                activity = random.choice(["work", "lunch", "meeting", "restroom", "coffee"])
                config["places"].append({
                    "name": name,
                    "activity": activity,
                    "building": "building1",
                    "department": None,
                    "area": 150.0,
                    "height": 2.7,
                    "capacity": 60,
                    "ventilation": 1.5,
                    "recirculated_flow_rate": 0,
                    "allow": True
                })

            num_events = len(config["events"])
            num_departments = len(config["people"])
            num_places = len(config["places"])

            num_people = 0
            for i in range(num_departments):
                if config["people"][i]["num_people"] is not None:
                    config["people"][i]["num_people"] *= ratio
                    config["people"][i]["num_people"] = int(config["people"][i]["num_people"])
                    num_people += config["people"][i]["num_people"]
            
            for j in range(num_places):
                if config["places"][j]["capacity"] is not None: 
                    config["places"][j]["capacity"] *= ratio
                    config["places"][j]["capacity"] = int(config["places"][j]["capacity"])

        
        
            time = timeit.repeat(lambda: main(config), number=1, repeat=1)[0]
            results.append({"num_people": num_people, "num_places": num_places, "num_events": num_events, "ratio": ratio, "number_runs": number_runs, "time": time})

pd.DataFrame(results).to_csv("performance.csv", index=False)



# print(results)

import json

with open("data/config.json", "r") as f:
    config = json.load(f)

from archABM.engine import Engine

simulation = Engine(config)
results = simulation.run()
# print(results)

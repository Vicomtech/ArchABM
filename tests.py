import json
from archABM.engine import Engine

with open("archABM/config.json", "r") as f:
    config = json.load(f)
simulation = Engine(config)
results = simulation.run()

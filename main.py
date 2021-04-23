
import json
with open("data/config.json", "r") as f:
    config = json.load(f)

from archABM.Engine import Engine
simulation = Engine(config)
results = simulation.run(1440)
print(results)
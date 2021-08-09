import json
from archABM.engine import Engine

experiments = range(8)

for xp in experiments:
    with open("experiments/config_" + str(xp) + ".json", "r") as f:
        print(xp)
        config = json.load(f)
    simulation = Engine(config)
    results = simulation.run()

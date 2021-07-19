import json
from archABM.engine import Engine

experiments = range(8)
# experiments = [0,1,3]
for xp in experiments:
    with open("data/config_" + str(xp) + ".json", "r") as f:
        print(xp)
        config = json.load(f)
    simulation = Engine(config)
    results = simulation.run()
# print(results)

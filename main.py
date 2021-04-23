# %% CONFIGURATION

# FROM EXCEL

import pandas as pd
config = pd.read_excel(io="data/config_new.ods", sheet_name=None)

config["events"] = config["events"].replace({float('nan'): None}).to_dict("records")
config["people"] = config["people"].replace({float('nan'): None}).to_dict("records")
config["places"] = config["places"].replace({float('nan'): None}).to_dict("records")
config["options"] = config["options"].replace({float('nan'): None}).set_index("option")["value"].to_dict()

import ast
for e in config["events"]:
    e["schedule"] = ast.literal_eval(e["schedule"])
    e["schedule"] = [[s[0] * 60, s[1] * 60] for s in e["schedule"]]

for p in config["places"]:
    if p["department"] is not None:
        if "," in p["department"]:
            p["department"] = p["department"].split(",")
        else:
            p["department"] = [p["department"]]


# with open("example.json", "w") as f:
#     json.dump(config, f)

# FROM JSON
import json
with open("data/config.json", "r") as f:
    config = json.load(f)

# preprocess config

# %% IMPORT MODULES

import time
from archABM.Engine import Engine

simulation = Engine(config)
start_time = time.time()
results = simulation.run(1440)
end_time = time.time()
print("time elapsed: %f" % (end_time - start_time))

# print(results)
import os
import json

here = os.path.dirname(__file__)
with open(os.path.join(here, 'config.json'), "r") as f:
    config = json.load(f)
# %% IMPORT MODULES

import pandas as pd
import time
from archABM.Engine import Engine

# %% CONFIGURATION
config = pd.read_excel(io="data/config.ods", sheet_name=None)

simulation = Engine(config)
start_time = time.time()
simulation.run(1440)
end_time = time.time()
print("time elapsed: %f" % (end_time - start_time))
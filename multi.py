# %% IMPORT MODULES

import pandas as pd
import time
from archABM.Engine import Engine

# %% CONFIGURATION
config = pd.read_excel(io="data/config.ods", sheet_name=None)


start_time_total = time.time()
for i in range(2):
    simulation = Engine(config)
    start_time = time.time()
    simulation.run(1440)
    end_time = time.time()
    print("[%d] time elapsed: %f" % (i, (end_time - start_time)))
end_time_total = time.time()
print("TOTAL time elapsed: %f" % (end_time_total - start_time_total))

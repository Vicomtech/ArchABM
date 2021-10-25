<img src="https://raw.githubusercontent.com/Vicomtech/ArchABM/main/docs/source/_static/logo_4.png" width="550"/>


Agent-based model simulation for air quality and pandemic risk assessment in architectural spaces.


[![PyPI Status](https://img.shields.io/pypi/status/archABM?style=flat-square)](https://pypi.python.org/pypi/archABM)
[![PyPI Version](https://img.shields.io/pypi/v/archABM?style=flat-square)](https://pypi.python.org/pypi/archABM)
[![License](https://img.shields.io/github/license/Vicomtech/ArchABM?style=flat-square)](https://github.com/Vicomtech/ArchABM/blob/master/LICENSE)
[![Actions](https://img.shields.io/github/workflow/status/Vicomtech/ArchABM/Build%20&%20publish%20to%20Pypi?style=flat-square)](https://github.com/Vicomtech/ArchABM/actions)
[![](https://img.shields.io/pypi/dd/archABM?style=flat-square)](https://pepy.tech/project/archABM)
[![Top Language](https://img.shields.io/github/languages/top/Vicomtech/ArchABM?style=flat-square)](https://github.com/Vicomtech/ArchABM)
[![Github Issues](https://img.shields.io/github/issues/Vicomtech/ArchABM?style=flat-square)](https://github.com/Vicomtech/ArchABM)

## User Guide

**archABM** is a fast and open source agent-based modelling framework that simulates complex human-building-interaction patterns and estimates indoor air quality across an entire building, while taking into account potential airborne virus concentrations.

----

**Disclaimer**: archABM is an evolving research tool designed to familiarize the interested user with factors influencing the potential indoor airborne transmission of viruses (such as SARS-CoV-2) and the generation of carbon-dioxide (CO2) indoors. 
Calculations of virus and CO2 levels within ArchABM are based on recently published aerosol models [1,2], which however have not been validated in the context of agent-based modeling (ABM) yet. We note that uncertainty in and intrinsic variability of model parameters as well as underlying assumptions concerning model parameters may lead to errors regarding the simulated results.
Use of archABM is the sole responsibility of the user. It is being made available without guarantee or warranty of any kind. The authors do not accept any liability from its use.

[1] *Peng, Zhe, and Jose L. Jimenez. "Exhaled CO2 as a COVID-19 infection risk proxy for different indoor environments and activities." Environmental Science & Technology Letters 8.5 (2021): 392-397.*

[2] *Lelieveld, Jos, et al. "Model calculations of aerosol transmission and infection risk of COVID-19 in indoor environments." International journal of environmental research and public health 17.21 (2020): 8114.*

----

Installation
------------

As the compiled **archABM** package is hosted on the Python Package
Index (PyPI) you can easily install it with `pip`. To install
**archABM**, run this command in your terminal of choice:

``` {.sourceCode .shell-session}
$ pip install archABM
```

or, alternatively:

``` {.sourceCode .shell-session}
$ python -m pip install archABM
```

If you want to get **archABM**'s latest version, you can refer to the
repository hosted at github:

``` {.sourceCode .shell-session}
python -m pip install https://github.com/Vicomtech/ArchABM/archive/main.zip
```

----

Getting Started
---------------

Use the following template to run a simulation with archABM:

```python
from archABM.engine import Engine
import json
import pandas as pd

# Read config data from JSON
def read_json(file_path):
    with open(str(file_path)) as json_file:
        result = json.load(json_file)
    return result

config_data = read_json("config.json")
# WARNING - for further processing ->
# config_data["options"]["return_output"] = True

# Create ArchABM simulation engine
simulation = Engine(config_data)

# Run simulation
results = simulation.run()

# Create dataframes based on the results
df_people = pd.DataFrame(results["results"]["people"])
df_places = pd.DataFrame(results["results"]["places"])
```

----

Developers can also use the command-line interface with the [main.py](https://github.com/Vicomtech/ArchABM) file from the source code repository.


<img src="https://raw.githubusercontent.com/Vicomtech/ArchABM/main/docs/source/_static/command.png" width="500" align="center"/>

```console
$ python main.py config.json
```

To run an example, use the [config.json]("data/config.json") found at the ``data`` directory of **archABM** repository.

Check the ``--help`` option to get more information about the optional parameters:

```
$ python main.py --help
Usage: main.py [OPTIONS] CONFIG_FILE

  ArchABM simulation helper

Arguments:
  CONFIG_FILE  The name of the configuration file  [required]

Options:
  -i, --interactive     Interactive CLI mode  [default: False]
  -l, --save-log        Save events logs  [default: False]
  -c, --save-config     Save configuration file  [default: True]
  -t, --save-csv        Export results to csv format  [default: True]
  -j, --save-json       Export results to json format  [default: False]
  -o, --return-output   Return results dictionary  [default: False]
  --install-completion  Install completion for the current shell.
  --show-completion     Show completion for the current shell, to copy it or
                        customize the installation.

  --help                Show this message and exit.
```

----

## Inputs 

In order to run a simulation, information about the `event` types,
`people`, `places`, and the `aerosol model` must be provided to the
ArchABM framework.

<details>
  <summary>Events</summary>
  
| Attribute | Description | Type |
|---|---|---|
| *name* | Event name | `string` |
| *schedule* | When an event is permitted to happen, in minutes | `list of tuples` |
| *duration* | Event duration lower and upper bounds, in minutes | `integer`,`integer` |
| *number of repetitions* | Number of repetitions lower and upper bounds | `integer`,`integer` |
| *mask efficiency* | Mask efficiency during an event [0-1] | `float` |
| *collective* | Event is invoked by one person but involves many | `boolean` |
| *allow* | Whether such event is allowed in the simulation | `boolean` |
 
</details>

<details>
  <summary>Places</summary>
  
| Attribute | Description | Type |
|:---:|:---:|:---:|
| *name* | Place name | `string` |
| *activity* | Activity or event occurring at that place | `string` |
| *department* | Department name | `string` |
| *building* | Building name | `string` |
| *area* | Room floor area in square meters | `float` |
| *height* | Room height in meters. | `float` |
| *capacity* | Room people capacity. | `integer` |
| *height* | Room height in meters. | `float` |
| *ventilation* | Passive ventilation in hours<sup>-1</sup> | `float` |
| *recirculated_flow_rate* | Active ventilation in cubic meters per hour | `float` |
| *allow* | Whether such place is allowed in the simulation | `boolean` |
 
</details>

<details>
  <summary>People</summary>
  
| Attribute | Description | Type |
|:---:|:---:|:---:|
| *department* | Department name | `string` |
| *building* | Building name | `string` |
| *num_people* | Number of people | `integer` |
 
</details>


<details>
  <summary>Aerosol Model</summary>
  
| Attribute | Description | Type |
|:---:|:---:|:---:|
| *pressure* | Ambient pressure in atm | `float` |
| *temperature* | Ambient temperature in Celsius degrees | `float` |
| *CO2_background* | Background CO2 concentration in ppm | `float` |
| *decay_rate* | Decay rate of virus in hours<sup>-1</sup> | `float` |
| *deposition_rate* | Deposition to surfaces in hours<sup>-1</sup> | `float` |
| *hepa_flow_rate* | Hepa filter flow rate in cubic meters per hour | `float` |
| *filter_efficiency* | Air conditioning filter efficiency | `float` |
| *ducts_removal* | Air ducts removal loss | `float` |
| *other_removal* | Extraordinary air removal | `float` |
| *fraction_immune* | Fraction of people immune to the virus | `float` |
| *breathing_rate* | Mean breathing flow rate in cubic meters per hour | `float` |
| *CO2_emission_person* | CO2 emission rate at 273K and 1atm | `float` |
| *quanta_exhalation* | Quanta exhalation rate in quanta per hour | `float` |
| *quanta_enhancement* | Quanta enhancement due to variants | `float` |
| *people_with_masks* | Fraction of people using mask | `float` |
 
</details>

<details>
  <summary>Options</summary>
  
| Attribute | Description | Type |
|:---:|:---:|:---:|
| *movement_buildings* | Allow people enter to other buildings | `boolean` |
| *movement_department* | Allow people enter to other departments | `boolean` |
| *number_runs* | Number of simulations runs to execute | `integer` |
| *save_log* | Save events logs | `boolean` |
| *save_config* | Save configuration file | `boolean` |
| *save_csv* | Export the results to csv format | `boolean` |
| *save_json* | Export the results to json format | `boolean` |
| *return_output* | Return a dictionary with the results | `boolean` |
| *directory* | Directory name to save results | `string` |
| *ratio_infected* | Ratio of infected to total number of people | `float` |
| *model* | Aerosol model to be used in the simulation | `string` |
 
</details>

#### Example config.json
<details>
  <summary>config.json</summary>
    
```json
{
    "events": [{
            "activity": "home",
            "schedule": [
                [0, 480],
                [1020, 1440]
            ],
            "repeat_min": 0,
            "repeat_max": null,
            "duration_min": 300,
            "duration_max": 360,
            "mask_efficiency": null,
            "collective": false,
            "shared": false,
            "allow": true
        },
        {
            "activity": "work",
            "schedule": [
                [480, 1020]
            ],
            "repeat_min": 0,
            "repeat_max": null,
            "duration_min": 30,
            "duration_max": 60,
            "mask_efficiency": 0.0,
            "collective": false,
            "shared": true,
            "allow": true
        },
        {
            "activity": "meeting",
            "schedule": [
                [540, 960]
            ],
            "repeat_min": 0,
            "repeat_max": 5,
            "duration_min": 20,
            "duration_max": 90,
            "mask_efficiency": 0.0,
            "collective": true,
            "shared": true,
            "allow": true
        },
        {
            "activity": "lunch",
            "schedule": [
                [780, 900]
            ],
            "repeat_min": 1,
            "repeat_max": 1,
            "duration_min": 20,
            "duration_max": 45,
            "mask_efficiency": 0.0,
            "collective": true,
            "shared": true,
            "allow": true
        },
        {
            "activity": "coffee",
            "schedule": [
                [600, 660],
                [900, 960]
            ],
            "repeat_min": 0,
            "repeat_max": 2,
            "duration_min": 5,
            "duration_max": 15,
            "mask_efficiency": 0.0,
            "collective": true,
            "shared": true,
            "allow": true
        },
        {
            "activity": "restroom",
            "schedule": [
                [480, 1020]
            ],
            "repeat_min": 0,
            "repeat_max": 4,
            "duration_min": 3,
            "duration_max": 6,
            "mask_efficiency": 0.0,
            "collective": false,
            "shared": true,
            "allow": true
        }
    ],
    "places": [{
            "name": "home",
            "activity": "home",
            "building": null,
            "department": null,
            "area": null,
            "height": null,
            "capacity": null,
            "ventilation": null,
            "recirculated_flow_rate": null,
            "allow": true
        },
        {
            "name": "open_office",
            "activity": "work",
            "building": "building1",
            "department": ["department1", "department2", "department3", "department4"],
            "area": 330.0,
            "height": 2.7,
            "capacity": 60,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "it_office",
            "activity": "work",
            "building": "building1",
            "department": ["department4"],
            "area": 52.0,
            "height": 2.7,
            "capacity": 10,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "chief_office_A",
            "activity": "work",
            "building": "building1",
            "department": ["department5", "department6", "department7"],
            "area": 21.0,
            "height": 2.7,
            "capacity": 5,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "chief_office_B",
            "activity": "work",
            "building": "building1",
            "department": ["department5", "department6", "department7"],
            "area": 21.0,
            "height": 2.7,
            "capacity": 5,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "chief_office_C",
            "activity": "work",
            "building": "building1",
            "department": ["department5", "department6", "department7"],
            "area": 24.0,
            "height": 2.7,
            "capacity": 5,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "meeting_A",
            "activity": "meeting",
            "building": "building1",
            "department": ["department1", "department2", "department3", "department5", "department6", "department7"],
            "area": 16.0,
            "height": 2.7,
            "capacity": 6,
            "ventilation": 1.0,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "meeting_B",
            "activity": "meeting",
            "building": "building1",
            "department": ["department1", "department2", "department3", "department5", "department6", "department7"],
            "area": 16.0,
            "height": 2.7,
            "capacity": 6,
            "ventilation": 1.0,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "meeting_C",
            "activity": "meeting",
            "building": "building1",
            "department": ["department1", "department2", "department3", "department5", "department6", "department7"],
            "area": 11.0,
            "height": 2.7,
            "capacity": 4,
            "ventilation": 1.0,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "meeting_D",
            "activity": "meeting",
            "building": "building1",
            "department": null,
            "area": 66.0,
            "height": 2.7,
            "capacity": 24,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "coffee_A",
            "activity": "coffee",
            "building": "building1",
            "department": null,
            "area": 25.0,
            "height": 2.7,
            "capacity": 10,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "coffee_B",
            "activity": "coffee",
            "building": "building1",
            "department": null,
            "area": 55.0,
            "height": 2.7,
            "capacity": 20,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "restroom_A",
            "activity": "restroom",
            "building": "building1",
            "department": null,
            "area": 20.0,
            "height": 2.7,
            "capacity": 4,
            "ventilation": 1.0,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "restroom_B",
            "activity": "restroom",
            "building": "building1",
            "department": ["department1", "department2", "department3", "department4", "department5", "department6"],
            "area": 20.0,
            "height": 2.7,
            "capacity": 4,
            "ventilation": 1.0,
            "recirculated_flow_rate": 0,
            "allow": true
        },
        {
            "name": "lunch",
            "activity": "lunch",
            "building": "building1",
            "department": null,
            "area": 150.0,
            "height": 2.7,
            "capacity": 60,
            "ventilation": 1.5,
            "recirculated_flow_rate": 0,
            "allow": true
        }
    ],
    "people": [{
            "department": "department1",
            "building": "building1",
            "num_people": 16
        },
        {
            "department": "department2",
            "building": "building1",
            "num_people": 16
        },
        {
            "department": "department3",
            "building": "building1",
            "num_people": 16
        },
        {
            "department": "department4",
            "building": "building1",
            "num_people": 7
        },
        {
            "department": "department5",
            "building": "building1",
            "num_people": 2
        },
        {
            "department": "department6",
            "building": "building1",
            "num_people": 2
        },
        {
            "department": "department7",
            "building": "building1",
            "num_people": 1
        }
    ],
    "options": {
        "movement_buildings": true,
        "movement_department": false,
        "number_runs": 1,
        "save_log": true,
        "save_config": true,
        "save_csv": false,
        "save_json": false,
        "return_output": false,
        "directory": null,
        "ratio_infected": 0.05,
        "model": "Colorado",
        "model_parameters": {
            "Colorado": {
                "pressure": 0.95,
                "temperature": 20,
                "CO2_background": 415,
                "decay_rate": 0.62,
                "deposition_rate": 0.3,
                "hepa_flow_rate": 0.0,
                "recirculated_flow_rate": 300,
                "filter_efficiency": 0.20,
                "ducts_removal": 0.10,
                "other_removal": 0.00,
                "fraction_immune": 0,
                "breathing_rate": 0.52,
                "CO2_emission_person": 0.005,
                "quanta_exhalation": 25,
                "quanta_enhancement": 1,
                "people_with_masks": 1.00
            }
        }
    }
}
```
</details>

----

## Outputs

Simulation outputs are stored by default in the `results` directory. The
subfolder with the results of an specific simulation have the date and
time of the moment when it was launched as a name in
`%Y-%m-%d_%H-%M-%S-%f` format.

By default, three files are saved after a simulation:

-   `config.json` stores a copy of the input configuration.
-   `people.csv` stores every person's state along time.
-   `places.csv` stores every places's state along time.

**archABM** offers the possibility of exporting the results in *JSON*
and *CSV* format. To export in *JSON* format, use the `--save-json`
parameter when running archABM. By default, the `--save-csv` parameter
is set to true.

Alternatively, **archABM** can also be configured to yield more detailed
information. The `app.log` file saves the log of the actions and events
occurred during the simulation. To export this file, use the
`--save-log` parameter when running archABM.

----

## Citing archABM

If you use ArchABM in your work or project, please cite the following article, published in Building and Environment (DOI...): [Full REF]

```bibtex
@article{
}
```
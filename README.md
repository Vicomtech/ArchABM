# ArchABM

Agent-based model for air quality and pandemic risk assessment in architectural spaces.

## Installation

```
pip install -e git+ssh://git@github.com/Vicomtech/ArchABM.git@deploy#egg=ArchABM
```


## How to run

```
python main.py data/config.json
```

### Example

```python
config = {
    "events": [
        {
            "activity": "work",
            "schedule": [[0, 192]],
            "repeat_min": 0,
            "repeat_max": None,
            "duration_min": 30,
            "duration_max": 60,
            "mask_efficiency": 0.7,
            "collective": False,
            "shared": True,
            "allow": True
        },
        {
            "activity": "meeting",
            "schedule": [[50, 135]],
            "repeat_min": 0,
            "repeat_max": 5,
            "duration_min": 15,
            "duration_max": 60,
            "mask_efficiency": 0.8,
            "collective": True,
            "shared": True,
            "allow": True
        },
    ],
    "people": [
        {
            "department": "department1",
            "building": "building1",
            "num_people": 10
        }
    ],
    "places": [
        {
            "name": "office1",
            "activity": "work",
            "building": "building1",
            "department": ["department1"],
            "area": 40.0,
            "height": 3.0,
            "capacity": 50.0,
            "allow": True
        },
        {
            "name": "meeting1",
            "activity": "meeting",
            "building": "building1",
            "department": None,
            "area": 30.0,
            "height": 3.0,
            "capacity": 10.0,
            "allow": True
        }
    ],
    "options": {
        "movement_buildings": True,
        "movement_department": True,
        "number_runs": 1,
        "room_ventilation": 0.3,
    }
}

from archABM.engine import Engine

simulation = Engine(config)
results = simulation.run(until=192)
print(results)
```


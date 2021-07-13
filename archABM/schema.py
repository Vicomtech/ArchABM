"""Schema
"""
schema = {
    "type": "object",
    "properties": {
        "events": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": True,
            "items": {
                "type": "object",
                "properties": {
                    "activity": {
                        "type": "string"
                    },
                    "schedule": {
                        "type": "array",
                        "minItems": 1,
                        "uniqueItems": True,
                        "items": {
                            "type": "array",
                            "minItems": 2,
                            "maxItems": 2,
                            "items": {
                                "type": "integer"
                            }
                        }
                    },
                    "repeat_min": {
                        "type": ["integer", "null"]
                    },
                    "repeat_max": {
                        "type": ["integer", "null"]
                    },
                    "duration_min": {
                        "type": "integer",
                        "minimum": 0
                    },
                    "duration_max": {
                        "type": "integer",
                        "minimum": 0
                    },
                    "mask_efficiency": {
                        "type": ["number", "null"],
                        "minimum": 0,
                        "maximum": 1
                    },
                    "collective": {
                        "type": "boolean"
                    },
                    "shared": {
                        "type": "boolean"
                    },
                    "allow": {
                        "type": "boolean"
                    }

                },
                "required": ["activity", "schedule", "repeat_min", "repeat_max", "duration_min", "duration_max", "mask_efficiency", "collective", "shared", "allow"]
            }
        },
        "people": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": True,
            "items": {
                "type": "object",
                "properties": {
                    "department": {
                        "type": "string"
                    },
                    "building": {
                        "type": "string"
                    },
                    "num_people": {
                        "type": "integer",
                        "minimum": 0
                    }
                }
            },
            "required": ["department", "building", "num_people"]
        },
        "places": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": True,
            "items": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string"
                    },
                    "activity": {
                        "type": "string"
                    },
                    "building": {
                        "type": ["string", "null"]
                    },
                    "department": {
                        "type": ["array", "null"],
                        "items": {
                            "type": "string"
                        },
                        "minItems": 1
                    },
                    "area": {
                        "type": ["number", "null"]
                    },
                    "height": {
                        "type": ["number", "null"]
                    },
                    "capacity": {
                        "type": ["integer", "null"]
                    },
                    "ventilation": {
                        "type": ["number", "null"]
                    },
                    "recirculated_flow_rate": {
                        "type": ["number", "null"]
                    },
                    "allow": {
                        "type": "boolean"
                    }
                }
            },
            "required": ["name", "activity", "building", "department", "area", "height", "capacity", "ventilation","recirculated_flow_rate","allow"]
        },
        "options": {
            "type": "object",
            "properties": {
                "movement_buildings": {
                    "type": "boolean"
                },
                "movement_department": {
                    "type": "boolean"
                },
                "number_runs": {
                    "type": "integer",
                    "minimum": 1
                },
                "ratio_infected": {
                    "type": "number",
                    "minimum": 0,
                    "maximum": 1
                },
                "directory": {
                    "type": ["string", "null"]
                },
                "model": {
                    "type": "string"
                },
                "model_parameters": {
                    "type": "object"
                }

            },
            "required": ["movement_buildings", "movement_department", "number_runs", "ratio_infected", "model", "model_parameters"]

        }
    },
    "required": ["events", "people", "places", "options"]
}
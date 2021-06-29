
class AerosolModel:
    """Aerosol transmission estimator"""
    name: None

    def __init__(self, params):
        self.params = params

    def get_risk(self, inputs):
        """Calculate the transmission risk of an individual in a room 
        and the dosis thrown into the air.

        Args:
            inputs (Parameters): dictionary of model inputs
        """
        pass
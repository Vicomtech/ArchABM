
class AerosolModel:
    """Aerosol transmission estimator"""
    name: None

    def __init__(self, params):
        self.params = params


    def get_person_risk(self, params):
        """Calculate the transmission risk of an individual in a room"

        Args:
            params (Parameters): dictionary of model parameters
        """
        pass

    def get_place_risk(self, params):
        """Calculate the risk in air quality of a place

        Args:
            params (Parameters): dictionary of model parameters
        """
        pass

    def get_risk(self, inputs):
        """Calculate the transmission risk of an individual in a room 
        and the dosis thrown into the air.

        Args:
            inputs (Parameters): dictionary of model inputs
        """
        pass
from typing import Tuple
from .parameters import Parameters


class AerosolModel:
    """Aerosol transmission estimator"""

    name: str
    params: Parameters

    def __init__(self, params: Parameters):
        self.params = params

    def get_risk(self, inputs: Parameters) -> Tuple[float, float]:
        """Calculate the infection risk of an individual in a room 
        and the CO\ :sub:`2` thrown into the air.

        Args:
            inputs (Parameters): model parameters 

        Returns:
            Tuple[float, float]: CO\ :sub:`2` concentration (ppm), and infection risk probability
        """
        return None, None

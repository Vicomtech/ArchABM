import math
from typing import Tuple

from .parameters import Parameters
from .aerosol_model import AerosolModel


class AerosolModelMaxPlanck(AerosolModel):
    """Aerosol transmission estimator
    
    Model Calculations of Aerosol Transmission and Infection Risk of COVID-19 in Indoor Environments :cite:`ijerph17218114`

    An adjustable algorithm to estimate the infection risk for different indoor environments, 
    constrained by published data of human aerosol emissions, SARS-CoV-2 viral loads, infective dose and other parameters. 
    Evaluates typical indoor settings such as an office, a classroom, choir practice, and a reception/party. 

    The model includes a number of modifiable environmental factors that represent relevant physiological parameters and environmental conditions. 
    For simplicity, all subjects are assumed to be equal in terms of breathing, speaking and susceptibility to infection. 
    The model parameters can be easily adjusted to account for different environmental conditions and activities. 
    
    """

    name: str = "MaxPlanck"

    def __init__(self, params):
        super().__init__(params)
        self.params = params

    def get_risk(self, inputs: Parameters) -> Tuple[float, float]:
        """Calculate the infection risk of an individual in a room 
        and the CO\ :sub:`2` thrown into the air.

        Args:
            inputs (Parameters): model parameters 

        Returns:
            Tuple[float, float]: CO\ :sub:`2` concentration (ppm), and infection risk probability
        """
        params = self.params
        # inputs: room_area, room_height, room_ventilation_rate, mask_efficiency, time_in_room_h, susceptible_people

        infection_probability = 1 - 10 ** (math.log10(0.5) / params.RNA_D50)
        RNA_content = params.RNA_concentration * math.pi / 6 * (params.aerosol_diameter / 10000) ** 3
        aerosol_emission = (params.emission_breathing * (1 - params.speaking_breathing_ratio) + params.emission_speaking * params.speaking_breathing_ratio) * 1000 * params.respiratory_rate * 60
        aerosol_concentration = aerosol_emission / (inputs.room_area * inputs.room_height * 1000)
        RNA_concentration = aerosol_concentration * RNA_content
        RNA_dosis = params.respiratory_rate * 60 * RNA_concentration * params.deposition_rate

        dosis_infectious = RNA_dosis / (inputs.room_ventilation_rate + 1 / params.virus_lifetime) * (1 - inputs.mask_efficiency) * inputs.time_in_room_h
        risk_one_person = (1 - ((1 - infection_probability) ** dosis_infectious) ** inputs.num_people) * 100

        # Return results
        dosis_min, dosis_max = 0, 1
        co2_min, co2_max = 0, 80
        co2_dosis = (dosis_infectious - dosis_min) / (dosis_max - dosis_min) * (co2_max - co2_min) + co2_min

        air_contamination = co2_dosis
        infection_risk = risk_one_person

        return air_contamination, infection_risk

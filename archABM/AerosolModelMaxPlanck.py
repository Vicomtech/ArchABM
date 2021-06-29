
from .AerosolModel import AerosolModel
import math

class AerosolModelMaxPlanck(AerosolModel):
    """Aerosol transmission estimator"""
    name: "MaxPlanck"

    def __init__(self, params):
        self.params = params

    def get_risk(self, inputs):
        """Calculate the transmission risk of an individual in a room 
        and the dosis thrown into the air.

        Args:
            inputs (Parameters): dictionary of model inputs
        """
        params = self.params
        # inputs: room_area, room_height, room_ventilation_rate, mask_efficiency, time_in_room_h, susceptible_people

        infection_probability = 1 - 10 ** ((math.log10(0.5) / params.RNA_D50))
        RNA_content = params.RNA_concentration * math.pi / 6 * (params.aerosol_diameter / 10000) ** 3
        aerosol_emission = (params.emission_breathing * (1 - params.speaking_breathing_ratio) + params.emission_speaking * params.speaking_breathing_ratio) * 1000 * params.respiratory_rate * 60
        aerosol_concentration = aerosol_emission / (inputs.room_area * inputs.room_height * 1000)
        RNA_concentration = aerosol_concentration * RNA_content
        RNA_dosis = params.respiratory_rate * 60 * RNA_concentration * params.deposition_rate

        dosis_infectious = RNA_dosis / (inputs.room_ventilation_rate + 1 / params.virus_lifetime) * (1 - inputs.mask_efficiency) * inputs.time_in_room_h
        risk_one_person = (1 - ((1 - infection_probability) ** dosis_infectious) ** inputs.susceptible_people) * 100
        
        return dosis_infectious, risk_one_person
        
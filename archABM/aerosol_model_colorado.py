import math
from typing import Tuple

from .aerosol_model import AerosolModel
from .parameters import Parameters


class AerosolModelColorado(AerosolModel):
    """Aerosol transmission estimator
                    
    COVID-19 Airborne Transmission Estimator :cite:`doi:10.1021/acs.estlett.1c00183,https://doi.org/10.1111/ina.12751,Peng2021.04.21.21255898`
    
    The model combines two submodels: 

    #. A standard atmospheric box model, which assumes that the emissions are completely mixed across a control volume quickly \
        (such as an indoor room or other space). \
        See for example Chapter 3 of the Jacob Atmos. Chem. textbook :cite:`10.2307/j.ctt7t8hg`, and Chapter 21 of the Cooper and \
        Alley Air Pollution Control Engineering Textbook :cite:`cooper2010air` for indoor applications. \
        This is an approximation that allows easy calculation, is approximately correct as long as near-field effects \
        are avoided by social distancing, and is commonly used in air quality modeling.

    #. A standard aerosol infection model (Wells-Riley model), as formulated in Miller et al. 2020 :cite:`https://doi.org/10.1111/ina.12751`,\
        and references therein :cite:`10.1093/oxfordjournals.aje.a112560,BUONANNO2020105794,BUONANNO2020106112`.		

    .. important::
        The propagation of COVID-19 is only by aerosol transmission. 

        The model is based on a standard model of aerosol disease transmission, the Wells-Riley model. 
        It is calibrated to COVID-19 per recent literature on quanta emission rate.

        This is not an epidemiological model, and does not include droplet or contact / fomite transmission, and assumes that 6 ft / 2 m social distancing is respected. Otherwise higher transmission will result.

    """

    name: str = "Colorado"

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

        # length = 8
        # width = 6
        height = inputs.room_height
        area = inputs.room_area  # width * length
        volume = area * height

        pressure = params.pressure  # 0.95
        temperature = params.temperature  # 20
        # relative_humidity = params.relative_humidity # 50
        CO2_background = params.CO2_background  # 415

        event_duration = inputs.event_duration  # 50 / 60 # h

        ventilation = inputs.room_ventilation_rate  # 3
        decay_rate = params.decay_rate  # 0.62
        deposition_rate = params.deposition_rate  # 0.3

        hepa_flow_rate = params.hepa_flow_rate
        hepa_removal = hepa_flow_rate * volume

        recirculated_flow_rate = inputs.recirculated_flow_rate
        filter_efficiency = params.filter_efficiency
        ducts_removal = params.ducts_removal
        other_removal = params.other_removal

        ach_additional = recirculated_flow_rate / volume * min(1, filter_efficiency + ducts_removal + other_removal)
        additional_measures = hepa_removal + ach_additional

        loss_rate = ventilation + decay_rate + deposition_rate + additional_measures

        # ventilation_person = volume * (ventilation + additional_measures) * 1000 / 3600 / num_people

        num_people = inputs.num_people
        infective_people = inputs.infective_people  # 1
        fraction_immune = params.fraction_immune  # 0
        susceptible_people = (num_people - infective_people) * (1 - fraction_immune)

        # density_area_person = area / num_people
        # density_people_area = num_people / area
        # density_volume_person = volume / num_people

        breathing_rate = params.breathing_rate  # 0.52
        breathing_rate_relative = breathing_rate / (0.0048 * 60)
        CO2_emission_person = params.CO2_emission_person  # 0.005
        CO2_emission = CO2_emission_person * num_people / pressure * (273.15 + temperature) / 273.15

        quanta_exhalation = params.quanta_exhalation  # 25
        quanta_enhancement = params.quanta_enhancement  # 1
        quanta_exhalation_relative = quanta_exhalation / 2

        mask_efficiency_exhalation = inputs.mask_efficiency  # 50 / 100
        mask_efficiency_inhalation = inputs.mask_efficiency  # 30 / 100
        people_with_masks = params.people_with_masks  # 100 / 100

        # probability_infective = 0.20 / 100
        # hospitalization_rate = 20 / 100
        # death_rate = 1 / 100

        net_emission_rate = quanta_exhalation * (1 - mask_efficiency_exhalation * people_with_masks) * infective_people * quanta_enhancement
        quanta_concentration = net_emission_rate / loss_rate / volume * (1 - (1 / loss_rate / event_duration) * (1 - math.exp(-loss_rate * event_duration)))
        # TODO: NEW FORMULA
        # TODO: infection risk dynamic
        quanta_concentration = (
            net_emission_rate / loss_rate / volume * (1 - (1 / loss_rate / event_duration) * (1 - math.exp(-loss_rate * event_duration)))
            + math.exp(-loss_rate * event_duration) * (inputs.quanta_level - 0)
            + 0
        )
        quanta_inhaled_per_person = quanta_concentration * breathing_rate * event_duration * (1 - mask_efficiency_inhalation * people_with_masks)

        # probability_infection = 1 - math.exp(-quanta_inhaled_per_person)
        # probability_infection = probability_infection * susceptible_people
        # probability_hospitalization = probability_infection * hospitalization_rate
        # probability_death = probability_infection * death_rate

        # if susceptible_people == 0 or infective_people == 0:
        #     infection_risk = 0.0
        #     infection_risk_relative = 0.0
        # else:
        # infection_risk = (
        #     breathing_rate_relative
        #     * quanta_exhalation_relative
        #     * (1 - mask_efficiency_exhalation * people_with_masks)
        #     * (1 - mask_efficiency_inhalation * people_with_masks)
        #     * event_duration
        #     * susceptible_people
        #     / (loss_rate * volume)
        #     * (1 - (1 - math.exp(-loss_rate * event_duration)) / (loss_rate * event_duration))
        #     + math.exp(-loss_rate * event_duration) * (inputs.infection_risk - 0)
        #     + 0
        # )

        # infection_risk_relative = infection_risk / susceptible_people
        # infection_risk = (1 - math.exp(-infection_risk_relative))*susceptible_people # TODO: review Taylor approximation

        CO2_mixing_ratio = (
            (CO2_emission * 3.6 / ventilation / volume * (1 - (1 / ventilation / event_duration) * (1 - math.exp(-ventilation * event_duration)))) * 1e6
            + math.exp(-ventilation * event_duration) * (inputs.CO2_level - CO2_background)
            + CO2_background
        )
        CO2_mixing_ratio_delta = CO2_mixing_ratio - inputs.CO2_level
        CO2_concentration = CO2_mixing_ratio_delta * 40.9 / 1e6 * 44 * 298 / (273.15 + temperature) * pressure
        CO2_reinhaled_grams = CO2_concentration * breathing_rate * event_duration
        CO2_reinhaled_ppm = CO2_mixing_ratio_delta * event_duration
        # CO2_probability_infection_=  CO2_reinhaled_ppm / 1e4 / probability_infection
        # CO2_inhale_ppm = CO2_mixing_ratio_delta * event_duration * 0.01 / probability_infection + CO2_background

        return CO2_mixing_ratio, quanta_inhaled_per_person, quanta_concentration

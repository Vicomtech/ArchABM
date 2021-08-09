from typing import Tuple
from .parameters import Parameters
from .aerosol_model import AerosolModel


class AerosolModelMIT(AerosolModel):
    """Aerosol transmission estimator
    
    MIT COVID-19 Indoor Safety Guideline :cite:`Bazante2018995118,Bazant2021.04.04.21254903,Risbeck2021.06.21.21259287`

    Theoretical model that quantifies the extent to which transmission risk is reduced in large rooms
    with high air exchange rates, increased for more vigorous respiratory activities, and dramatically reduced by the use of face masks. 
    Consideration of a number of outbreaks yields self-consistent estimates for the infectiousness of the new coronavirus.
    
    """

    name: str = "MIT"

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

        area = inputs.room_area
        height = inputs.room_height
        volume = area * height

        ventilation = inputs.room_ventilation_rate
        ventilation_flow = ventilation * volume

        recirculation = 1
        recirculation_flow = recirculation * volume

        air_flow = ventilation_flow + recirculation_flow
        air_outdoor_fraction = ventilation_flow / air_flow

        filtration_efficiency = params.filtration_efficiency  # 0.01
        filtration_rate = filtration_efficiency * recirculation_flow / volume
        relative_humidity = params.relative_humidity / 100  # 60 / 100

        breathing_rate = params.breathing_rate  # 0.49
        aerosol_radius = params.aerosol_radius  # 2
        aerosol_radius_humidity = aerosol_radius * (0.4 / (1 - relative_humidity)) ** (1 / 3)

        infectiousness = params.infectiousness  # 72
        deactivation_rate = params.deactivation_rate  # 0.3
        deactivation_rate_humidity = deactivation_rate * relative_humidity / 50
        transmissibility = params.transmissibility  # 1

        settling_speed = (2 / 9) * 1100 / (1.86 * 10 ** (-5)) * 9.8 / 1e9 * aerosol_radius_humidity ** 2  # * 60 * 60 / 1000
        relaxation_rate = ventilation + deactivation_rate_humidity + filtration_rate + settling_speed * 60 * 60 / 1000 / ventilation
        dillution_factor = breathing_rate / (relaxation_rate * volume)
        infectiousness_room = infectiousness * dillution_factor

        mask_passage_probability = 1 - inputs.mask_efficiency  # 0.145
        transmission_rate = (breathing_rate * mask_passage_probability) ** 2 * infectiousness * transmissibility / (volume * relaxation_rate)

        # if risk tolerance is fixed
        # risk_tolerance = 0.1
        # exposure_time = inputs.time_in_room_h # 10
        # maximum_occupancy_transient = 1 + risk_tolerance * (1 + 1/(relaxation_rate*exposure_time)) / (transmission_rate * exposure_time)
        # maximum_occupancy_steady = 1 + risk_tolerance / (transmission_rate * exposure_time)

        # occupancy = inputs.num_people
        # maximum_exposure_time_steady = risk_tolerance / (occupancy - 1) / transmission_rate
        # maximum_exposure_time_transient = maximum_exposure_time_steady * (1 + math.sqrt(1 + 4/(relaxation_rate*maximum_exposure_time_steady) )) / 2

        # background_co2 = params.background_co2 # 410
        # average_co2 = params.average_co2 # 700
        # maximum_exposure_time_co2 = risk_tolerance * 38000 * relaxation_rate / \
        #     ((average_co2 - background_co2) * breathing_rate * infectiousness * \
        #     transmissibility * mask_passage_probability * mask_passage_probability * ventilation )

        # co2_concentration = background_co2 + risk_tolerance * 38000 * relaxation_rate / (exposure_time * breathing_rate * infectiousness * transmissibility * mask_passage_probability * mask_passage_probability * ventilation)

        # if exposure time and occupancy is fixed
        exposure_time = inputs.time_in_room_h  # 10
        occupancy = inputs.num_people
        risk_tolerance_steady = (occupancy - 1) * transmission_rate * exposure_time
        risk_tolerance_transient = risk_tolerance_steady / (1 + 1 / (relaxation_rate * exposure_time))

        background_co2 = params.background_co2  # 410
        co2_concentration = background_co2 + risk_tolerance_steady * 38000 * relaxation_rate / (
            exposure_time * breathing_rate * infectiousness * transmissibility * mask_passage_probability * mask_passage_probability * ventilation
        )

        # Return results
        air_contamination = co2_concentration - background_co2
        infection_risk = risk_tolerance_steady

        print("hey", risk_tolerance_steady, relaxation_rate, exposure_time, breathing_rate, infectiousness, transmissibility, mask_passage_probability, ventilation)

        return air_contamination, infection_risk

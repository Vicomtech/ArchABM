
from .AerosolModel import AerosolModel
import math

class AerosolModelMIT(AerosolModel):
    """Aerosol transmission estimator"""

    def __init__(self, params):
        self.params = params

    def get_risk(self, inputs):
        """Calculate the transmission risk of an individual in a room 
        and the dosis thrown into the air.

        Args:
            inputs (Parameters): dictionary of model inputs
        """

        params = self.params

        inputs = Parameters({
            "room_area": self.params.area,
            "room_height": self.params.height,
            "room_ventilation_rate": self.params.ventilation,
            "mask_efficiency": self.event.params.mask_efficiency,
            "time_in_room_h": time_in_room_h,
            "susceptible_people": susceptible_people
        })

        area = inputs.room_area
        height = inputs.room_height
        volume = area * height

        ventilation = inputs.room_ventilation_rate
        ventilation_flow = ventilation * volume

        recirculation = 1
        recirculation_flow = recirculation * volume

        air_flow = ventilation_flow + recirculation_flow
        air_outdoor_fraction = ventilation_flow / air_flow

        filtration_efficiency = params.filtration_efficiency # 0.01
        filtration_rate = filtration_efficiency * recirculation_flow / volume
        relative_humidity = params.relative_humidity / 100 # 60 / 100

        breathing_rate = params.breathing_rate # 0.49
        aerosol_radius = params.aerosol_radius # 2
        aerosol_radius_humidity = aerosol_radius * ( 0.4 / (1-relative_humidity))**(1/3)

        infectiousness = params.infectiousness # 72
        deactivation_rate = params.deactivation_rate # 0.3
        deactivation_rate_humidity = deactivation_rate * relative_humidity / 50
        transmissibility = params.transmissibility # 1

        settling_speed = (2/9) * 1100 / (1.86*10**(-5)) * 9.8 / 1e9 * aerosol_radius_humidity**2 # * 60 * 60 / 1000
        relaxation_rate = ventilation + deactivation_rate_humidity + filtration_rate + settling_speed * 60 * 60 / 1000 / ventilation
        dillution_factor = breathing_rate / (relaxation_rate * volume)
        infectiousness_room = infectiousness * dillution_factor

        mask_passage_probability = 1 - inputs.mask_efficiency # 0.145
        transmission_rate = (breathing_rate * mask_passage_probability)**2*infectiousness*transmissibility/(volume*relaxation_rate)
        risk_tolerance = 0.1

        exposure_time = inputs.time_in_room_h # 10
        maximum_occupancy_transient = 1 + risk_tolerance * (1 + 1/(relaxation_rate*exposure_time)) / (transmission_rate * exposure_time)
        maximum_occupancy_steady = 1 + risk_tolerance / (transmission_rate * exposure_time)

        occupancy = inputs.susceptible_people
        maximum_exposure_time_steady = risk_tolerance / (occupancy - 1) / transmission_rate
        maximum_exposure_time_transient = maximum_exposure_time_steady * (1 + math.sqrt(1 + 4/(relaxation_rate*maximum_exposure_time_steady) )) / 2

        background_co2 = inputs.background_co2 # 410
        average_co2 = params.average_co2 # 700
        maximum_exposure_time_co2 = risk_tolerance * 38000 * relaxation_rate / \
            ((average_co2 - background_co2) * breathing_rate * infectiousness * \
            transmissibility * mask_passage_probability * mask_passage_probability * ventilation )

        co2_concentration = background_co2 + risk_tolerance * 38000 * relaxation_rate / (exposure_time * breathing_rate * infectiousness * transmissibility * mask_passage_probability * mask_passage_probability * ventilation)




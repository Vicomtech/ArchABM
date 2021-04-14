import math


class PropagationModel:
    def __init__(self):
        pass

    @staticmethod
    def get_infection_prob(RNA_50_perc_infection_prob):
        return 1 - 10 ** ((math.log10(0.5) / RNA_50_perc_infection_prob))

    @staticmethod
    def get_rna_in_aerosol(respiratory_fluid_RNA_conc, mean_wet_aerosol_diameter):
        return respiratory_fluid_RNA_conc * math.pi / 6 * (mean_wet_aerosol_diameter / 10000) ** 3

    @staticmethod
    def get_aerosol_emission(emission_breathing, emission_speaking, speaking_breathing_ratio, respiratory_rate):
        return (emission_breathing * (1 - speaking_breathing_ratio) + emission_speaking * speaking_breathing_ratio) * 1000 * respiratory_rate * 60

    @staticmethod
    def get_aerosol_conc(aerosol_emission, room_area, room_height):
        return aerosol_emission / (room_area * room_height * 1000)

    @staticmethod
    def get_rna_cont(aerosol_conc, rna_in_aerosol):
        return aerosol_conc * rna_in_aerosol

    @staticmethod
    def get_rna_dosis(respiratory_rate, rna_cont, deposition_probability):
        return respiratory_rate * 60 * rna_cont * deposition_probability

    @staticmethod
    def get_dosis_six_hours(
        rna_dosis, room_ventilation_rate, virus_lifetime_in_aerosol, total_mask_efficiency_exhaling_inhaling,
    ):
        return rna_dosis / (room_ventilation_rate + 1 / virus_lifetime_in_aerosol) * (1 - total_mask_efficiency_exhaling_inhaling) * 6

    @staticmethod
    def get_dosis_infectious(dosis_six_hours, time_in_room_h):
        # infectious_episode_d = 2 => 12 hours
        return dosis_six_hours * time_in_room_h / 6

    @staticmethod
    def get_individual_infection_risk(infection_probability, dosis_infectious):
        return (1 - (1 - infection_probability) ** dosis_infectious) * 100

    @staticmethod
    def get_risk_one_person(infection_probability, dosis_infectious, susceptible_people):
        return (1 - ((1 - infection_probability) ** dosis_infectious) ** susceptible_people) * 100

    @staticmethod
    def get_max_people_in_room(room_area_m2, secure_distance_m=1.5):
        if room_area_m2 and secure_distance_m:
            r = secure_distance_m / 2
            area_circle = round((math.pi * r ** 2), 1)
            print("SECURE AREA", area_circle)
            max_no_persons = math.floor(room_area_m2 / area_circle)  # round down
            return max_no_persons
        return 2

    @staticmethod
    def calculate_risk(
        RNA_50_perc_infection_prob,
        deposition_probability,
        emission_breathing,
        emission_speaking,
        speaking_breathing_ratio,
        respiratory_rate,
        respiratory_fluid_RNA_conc,
        mean_wet_aerosol_diameter,
        time_in_room_h,
        virus_lifetime_in_aerosol,
        room_area,
        room_height,
        room_ventilation_rate,
        total_mask_efficiency,
        susceptible_people,
    ):

        infection_prob = get_infection_prob(RNA_50_perc_infection_prob)  # 0.0022

        rna_in_aerosol = get_rna_in_aerosol(respiratory_fluid_RNA_conc, mean_wet_aerosol_diameter)  # 3.27E-02

        aerosol_emission = get_aerosol_emission(emission_breathing, emission_speaking, speaking_breathing_ratio, respiratory_rate,)  # 68400.0000

        aerosol_conc = get_aerosol_conc(aerosol_emission, room_area, room_height)  # 0.3800

        rna_cont = get_rna_cont(aerosol_conc, rna_in_aerosol)  # 0.0124

        rna_dosis = get_rna_dosis(respiratory_rate, rna_cont, deposition_probability)  # 3.7306

        dosis_six_hours = get_dosis_six_hours(rna_dosis, room_ventilation_rate, virus_lifetime_in_aerosol, total_mask_efficiency,)  # 23.9

        dosis_infectious = get_dosis_infectious(dosis_six_hours, time_in_room_h)  # 47.7

        individual_infection_risk = get_individual_infection_risk(infection_prob, dosis_infectious)  # 9.9

        risk_one_person = get_risk_one_person(infection_prob, dosis_infectious, susceptible_people,)  # 91.9

        return (
            dosis_six_hours,
            dosis_infectious,
            individual_infection_risk,
            risk_one_person,
        )
        # d = 3
        # return (
        #     round(dosis_six_hours, d),
        #     round(dosis_infectious, d),
        #     round(individual_infection_risk, d),
        #     round(risk_one_person, d),
        # )

    @staticmethod
    def test_default():
        RNA_50_perc_infection_prob = 316
        deposition_probability = 0.5
        emission_breathing = 0.06
        emission_speaking = 0.6
        speaking_breathing_ratio = 0.1
        respiratory_rate = 10
        respiratory_fluid_RNA_conc = 5e8
        mean_wet_aerosol_diameter = 5
        virus_lifetime_in_aerosol = 1.7

        susceptible_people = 24
        total_mask_efficiency = 0
        room_ventilation_rate = 0.35
        room_area = 60
        room_height = 3
        time_in_room_h = 12

        return get_calculate_risk(
            RNA_50_perc_infection_prob,
            deposition_probability,
            emission_breathing,
            emission_speaking,
            speaking_breathing_ratio,
            respiratory_rate,
            respiratory_fluid_RNA_conc,
            mean_wet_aerosol_diameter,
            time_in_room_h,
            virus_lifetime_in_aerosol,
            room_area,
            room_height,
            room_ventilation_rate,
            total_mask_efficiency,
            susceptible_people,
        )

    @staticmethod
    def get_risk(
        susceptible_people, total_mask_efficiency, room_ventilation_rate, room_area, room_height, time_in_room_h,
    ):
        RNA_50_perc_infection_prob = 316
        deposition_probability = 0.5
        emission_breathing = 0.06
        emission_speaking = 0.6
        speaking_breathing_ratio = 0.1
        respiratory_rate = 10
        respiratory_fluid_RNA_conc = 5e8
        mean_wet_aerosol_diameter = 5
        virus_lifetime_in_aerosol = 1.7

        # susceptible_people = 24
        # total_mask_efficiency = 0
        # room_ventilation_rate = 0.35
        # room_area = 60
        # room_height = 3
        # time_in_room_h = 12

        return get_calculate_risk(
            RNA_50_perc_infection_prob,
            deposition_probability,
            emission_breathing,
            emission_speaking,
            speaking_breathing_ratio,
            respiratory_rate,
            respiratory_fluid_RNA_conc,
            mean_wet_aerosol_diameter,
            time_in_room_h,
            virus_lifetime_in_aerosol,
            room_area,
            room_height,
            room_ventilation_rate,
            total_mask_efficiency,
            susceptible_people,
        )

    def start(self, total_mask_efficiency, room_ventilation_rate, room_area, room_height):
        RNA_50_perc_infection_prob = 316
        deposition_probability = 0.5
        emission_breathing = 0.06
        emission_speaking = 0.6
        speaking_breathing_ratio = 0.1
        respiratory_rate = 10
        respiratory_fluid_RNA_conc = 5e8
        mean_wet_aerosol_diameter = 5
        virus_lifetime_in_aerosol = 1.7

        self.infection_prob = self.get_infection_prob(RNA_50_perc_infection_prob)  # 0.0022
        rna_in_aerosol = self.get_rna_in_aerosol(respiratory_fluid_RNA_conc, mean_wet_aerosol_diameter)  # 3.27E-02
        aerosol_emission = self.get_aerosol_emission(emission_breathing, emission_speaking, speaking_breathing_ratio, respiratory_rate)  # 68400.0000
        aerosol_conc = self.get_aerosol_conc(aerosol_emission, room_area, room_height)  # 0.3800
        rna_cont = self.get_rna_cont(aerosol_conc, rna_in_aerosol)  # 0.0124
        rna_dosis = self.get_rna_dosis(respiratory_rate, rna_cont, deposition_probability)  # 3.7306
        self.dosis_six_hours = self.get_dosis_six_hours(rna_dosis, room_ventilation_rate, virus_lifetime_in_aerosol, total_mask_efficiency,)  # 23.9

    def get_risk_optimized(
        self, susceptible_people, time_in_room_h,
    ):

        # change: susceptible_people, time_in_room_h,

        dosis_infectious = self.get_dosis_infectious(self.dosis_six_hours, time_in_room_h)  # 47.7

        individual_infection_risk = self.get_individual_infection_risk(self.infection_prob, dosis_infectious)  # 9.9

        risk_one_person = self.get_risk_one_person(self.infection_prob, dosis_infectious, susceptible_people)  # 91.9

        return (
            self.dosis_six_hours,
            dosis_infectious,
            individual_infection_risk,
            risk_one_person,
        )


if __name__ == "__main__":
    print(PropagationModel().test_default())

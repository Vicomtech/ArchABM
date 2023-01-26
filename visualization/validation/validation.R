library(magrittr)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')
Sys.setenv(LANG = "en_US.UTF-8")


# EMPIRICAL DATA ----------------------------------------------------------

df <- data.table::fread("Occupancy-detection-data-master/datatest.txt", drop = 1)

# sensor: Telaire 6613, accuracy 400-1250 +. 30 ppm and 1250-2000 +- 5% of reading + 30ppm
# room: 5.85m x 3.50m x 3.53m
df %>% 
  dplyr::filter("2015-02-03 06:00" < date & date < "2015-02-03 18:00") %>% 
  tidyr::pivot_longer(-date) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=value, color=name))+
  ggplot2::facet_grid(dplyr::vars(name), scales="free_y")

df_empirical <- df %>% 
  dplyr::filter("2015-02-03 07:00:00" < date & date < "2015-02-03 18:00:00") %>% 
  dplyr::mutate(
    hour = lubridate::hour(date),
    minutes = lubridate::minute(date),
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT")
  ) %>% 
  dplyr::select(date, CO2) %>% 
  dplyr::mutate(
    CO2_error = ifelse(dplyr::between(CO2, 400, 1250), 30, 0.05*CO2 + 30),
    CO2_mean = CO2,
    CO2_upper = CO2_mean + CO2_error,
    CO2_lower = CO2_mean - CO2_error
  )

# IMPORT ------------------------------------------------------------------

experiments <- list.files(path = "../../results/validation/", full.names = T)
n <- length(experiments)

experiment <- experiments[n]

config_file <- file.path(experiment, "config.json")
places_file <- file.path(experiment, "places.csv")
people_file <- file.path(experiment, "people.csv")

print(experiment)
config <- jsonlite::fromJSON(config_file)


places <- data.table::fread(places_file) %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT")
  ) %>% 
  dplyr::group_by(run, place) %>% 
  dplyr::mutate(
    CO2_level_delta = CO2_level - dplyr::lag(CO2_level, default=CO2_level[1]),
    quanta_level_delta = quanta_level - dplyr::lag(quanta_level, default=quanta_level[1]),
  ) %>% 
  dplyr::mutate(
    infective_people_mean = mean(infective_people, na.rm=T),
    CO2_level_max = max(CO2_level, na.rm=T),
    quanta_level_max = max(quanta_level, na.rm=T),
    CO2_level_delta_max = max(CO2_level_delta, na.rm=T),
    quanta_level_delta_max = max(quanta_level_delta, na.rm=T),
  ) %>%
  dplyr::ungroup()

people <- data.table::fread(people_file) %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT")
  ) %>% 
  dplyr::mutate(infection_risk = 1 - exp(-quanta_inhaled)) %>% 
  dplyr::group_by(run, person) %>% 
  dplyr::arrange(time) %>% 
  dplyr::mutate(
    elapsed = time - dplyr::lag(time, default = 0),
    quanta_inhaled_delta = quanta_inhaled - dplyr::lag(quanta_inhaled, default=quanta_inhaled[1]),
  ) %>%
  dplyr::mutate(
    CO2_level_mean = weighted.mean(CO2_level, elapsed, na.rm=T),
    quanta_inhaled_max = max(quanta_inhaled, na.rm=T),
    quanta_inhaled_delta_max = max(quanta_inhaled_delta, na.rm=T),
  ) %>% 
  dplyr::ungroup()


events_info <- config$events %>% 
  tibble::rowid_to_column(var = "event") %>% 
  dplyr::mutate(event = event-1)

places_info <- config$places %>% 
  tibble::rowid_to_column(var = "place") %>% 
  dplyr::mutate(place = place-1)

people_info <- config$people %>% 
  tibble::rowid_to_column(var = "person") %>% 
  dplyr::mutate(person = person-1)

places <- merge(places, places_info, by = "place")
people <- merge(people, people_info, by = "person")
people <- merge(people, events_info, by = "event")


# VISUALIZATION -----------------------------------------------------------

color_palette <- ggsci::pal_d3()(2)
places %>% 
  dplyr::filter(name == "office") %>% 
  dplyr::filter(run == 0) %>%
  dplyr::mutate(
    CO2_level_noise = CO2_level + rnorm(dplyr::n(), 0, 5)
  ) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(data = df_empirical, ggplot2::aes(x=date, y=CO2, color="Empirical data"))+
  ggplot2::geom_ribbon(data = df_empirical, ggplot2::aes(x=date, ymin=CO2_lower, ymax=CO2_upper), fill=color_palette[1], alpha=0.2)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=CO2_level_noise, group=run, color="Simulated data"), 
                     alpha=1, size=1, linetype="solid")+
  ggplot2::scale_color_manual(values=color_palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::labs(x =NULL, y=latex2exp::TeX("$CO_2 \\, (ppm)$"), color=NULL)+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = c(0.82, 0.13),
    legend.background = ggplot2::element_blank(),
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
  )

ggplot2::ggsave("validation.pdf", width=5, height=3, device = cairo_pdf)
  


# people %>% 
#   dplyr::filter(activity == "work") %>% 
#   dplyr::filter(run == 0) %>% 
#   ggplot2::ggplot()+
#   ggplot2::geom_line(ggplot2::aes(x=date, y=CO2_level, color=name))+
#   ggplot2::geom_point(ggplot2::aes(x=date, y=CO2_level))




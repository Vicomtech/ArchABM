library(magrittr)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')
Sys.setenv(LANG = "en_US.UTF-8")
extrafont::loadfonts(quiet = T)

# IMPORT ------------------------------------------------------------------

experiments <- list.files(path = "../results", full.names = T)
n <- length(experiments)
if(n == 0){
  stop("No experiments found")
}

experiment <- experiments[1]

config_file <- file.path(experiment, "config.json")
places_file <- file.path(experiment, "places.csv")
people_file <- file.path(experiment, "people.csv")


print(experiment)
config <- jsonlite::fromJSON(config_file)
places <- data.table::fread(places_file) %>% 
  dplyr::filter(run == 0) %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT")
  )
people <- data.table::fread(people_file) %>%
  dplyr::mutate(infection_risk = 1 - exp(-quanta_inhaled)) %>% 
  dplyr::filter(run == 0) %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz = "GMT")
  )

events_info <- config$events %>% 
  tibble::rowid_to_column(var = "event") %>% 
  dplyr::mutate(event = event-1)

places_info <- config$places %>% 
  tibble::rowid_to_column(var = "place") %>% 
  dplyr::mutate(place = place-1) %>% 
  dplyr::select(-activity)

people_info <- config$people %>% 
  tibble::rowid_to_column(var = "person") %>% 
  dplyr::mutate(person = person-1)

places <- merge(places, places_info, by = "place")
people <- merge(people, people_info, by = "person")
people <- merge(people, events_info, by = "event")



# COLOR PALETTE
values <- places_info$activity %>% unlist() %>% unique() %>% sort()
palette <- c("#BF506E", "#34B1BF", "#89BF7A", "#571FA6", "#9cadbc", "#F2B950")
# palette <- ggsci::pal_npg()(6)  # JAMA, JCO, LOCUSZOOM, NPG, NEJM
names(palette) <- values
# scales::show_col(palette)

# REMOVEEEE
date_limits <- lubridate::hm(c("06:15", "18:00")) %>% as.POSIXct(origin="1970-01-01", tz="GMT")
# Timeline: temperature per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=temperature, color=activity, group=name), alpha=0.5)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=temperature, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 7)+
  # ggplot2::facet_grid(cols=dplyr::vars(name), )
  # ggplot2::ggtitle("Timeline: air quality at each place",
  #                  "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x=NULL, y="Temperature (ºC)", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent")
  )

# STATUS
people %>% dplyr::filter(status==1) %>% dplyr::distinct(person, department, building, name)

# DATA VIZ ----------------------------------------------------------------

pdf(file.path(experiment, "results.pdf"), 12, 8)


# COUNTS ------------------------------------------------------------------


# Count: number events at each place
places %>% 
  dplyr::group_by(name, activity) %>% 
  dplyr::summarise(num_events=dplyr::n(), .groups = "keep") %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(activity_num = activity %>%  as.factor %>%  as.numeric) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_col(ggplot2::aes(x=reorder(name, activity_num), y=num_events, fill=activity), alpha=0.9, width=0.55)+
  ggplot2::geom_text(ggplot2::aes(x=name, y=num_events, label=num_events, color=activity),
                     alpha=0.9, size=4, vjust=0, show.legend = F)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_y_continuous(n.breaks = 8)+
  # ggplot2::coord_flip()+
  ggplot2::ggtitle("Number of events per place", 
                   "Count number of events that happen at each place. \nFor example, most frequent places are related to work activity")+
  ggplot2::labs(x="Place", y="# Events", fill="Activity")+
  ggplot2::guides(fill=ggplot2::guide_legend(nrow=1,byrow=TRUE))+
  # ggplot2::theme_bw(base_family = "Ubuntu")+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=35, hjust=1),
  )

people %>% 
  # merge(config$events, by="activity") %>% 
  dplyr::add_count(name, activity, name = "count") %>% 
  # dplyr::mutate(repeat_max = ifelse(is.na(repeat_max), max(count), repeat_max)) %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(ggplot2::aes(y=activity, x=count, fill=activity), 
                                scale=0.75, alpha=0.2, color="gray", stat = "binline", binwidth=1)+
  ggplot2::geom_jitter(ggplot2::aes(y=activity %>% as.factor %>% as.numeric - 0.1, x=count, color=activity),
                       width = 0.1, height=0.1, alpha=0.1, shape=19, size=0.5, show.legend = F)+
  # ggplot2::geom_text(ggplot2::aes(x=activity, y=repeat_max, label="MAX"), 
  #                    color = "red", fontface="bold", check_overlap = T, na.rm=T, nudge_x = -0.3, nudge_y=0.5)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, repeat_max),
                      ggplot2::aes(y=activity, x=repeat_max), color = "black", fill="black", shape=25, na.rm=T)+
  # ggplot2::geom_text(ggplot2::aes(x=activity, y=repeat_min, label="MIN"), 
  #                    color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=-0.5)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, repeat_min),
                      ggplot2::aes(y=activity, x=repeat_min), 
                      color = "black", fill="black", shape=24)+
  ggplot2::geom_text(
    data = . %>% dplyr::count(activity, count, name="countcount") %>% 
      dplyr::group_by(activity) %>% dplyr::mutate(countcount_rel = countcount / sum(countcount)),
    ggplot2::aes(y=as.numeric(factor(activity)) + countcount_rel*0.75, x=count, label=countcount, color=activity), 
    vjust = 0.5, hjust=-0.5, size = 3, check_overlap = T, show.legend = F 
  )+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_x_continuous(n.breaks = 10, limits=c(0, NA))+
  ggplot2::coord_flip()+
  ggplot2::ggtitle("Number of events per person",
                   "Count number of activities each person does. Repeat min/max are included as reference in red color.\nGives an idea of how many times each person repeats an activity")+
  ggplot2::labs(y="Activity", x="# Events per person", color="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=40, hjust=1),
  )



people %>% 
  dplyr::group_by(name) %>% 
  dplyr::arrange(time) %>% 
  dplyr::mutate(elapsed = dplyr::lead(time)-time) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(ggplot2::aes(y=activity, x=elapsed, fill=activity), 
                                scale=0.5, alpha=0.2, color="gray", stat = "binline", binwidth=15, na.rm = T)+
  ggplot2::geom_jitter(ggplot2::aes(y=activity %>% as.factor %>% as.numeric - 0.1, x=elapsed, color=activity), 
                       width = 0.1, height=0.1, alpha=0.1, shape=19, size=0.5, na.rm=T, show.legend = F)+
  # ggplot2::geom_text(ggplot2::aes(x=activity, y=duration_max, label="MAX"), 
  #                    color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=10)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, duration_max),
                      ggplot2::aes(y=activity, x=duration_max), color = "black", fill="black", shape=25)+
  # ggplot2::geom_text(ggplot2::aes(x=activity, y=duration_min, label="MIN"), 
  #                    color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=-10)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, duration_min),
                      ggplot2::aes(y=activity, x=duration_min), color = "black", fill="black", shape=24)+
  ggplot2::geom_text(
    data = . %>% dplyr::mutate(elapsedbin = 15*round(elapsed / 15)) %>% 
      dplyr::count(activity, elapsedbin, name="count") %>%
      dplyr::group_by(activity) %>% dplyr::mutate(count_rel = count / sum(count)),
    ggplot2::aes(y=as.numeric(factor(activity)) + count_rel*0.5, x=elapsedbin, label=count, color=activity),
    vjust = 0.5, hjust=-0.5, size = 3, check_overlap = T, show.legend = F, na.rm=T
  )+
  ggplot2::coord_flip()+
  # ggplot2::scale_x_continuous(limits=c(0,NA))+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::ggtitle("Duration of events per person",
                   "How much time each person stays in the same place doing an activity. Duration min/max are included as reference in red color\nIt is possible to exceed these limits, since a person can stay in the same place for multiple consecutive events")+
  ggplot2::labs(y="Activity", x="# Duration of events per person", color="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=40, hjust=1),
  )


# TIMELINE ----------------------------------------------------------------

date_limits <- lubridate::hm(c("06:15", "18:00")) %>% as.POSIXct(origin="1970-01-01", tz="GMT")
departments <- people_info %>% dplyr::group_by(department) %>% 
  dplyr::summarise(start = dplyr::first(person)-0.5, stop = dplyr::last(person)+0.5) %>% 
  dplyr::mutate(hour=6, minutes=0, date_start = paste0("1970-01-01 ", hour , ":", minutes),
                date_start = as.POSIXct(date_start, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT"),
                hour=19, minutes=0, date_stop = paste0("1970-01-01 ", hour , ":", minutes),
                date_stop = as.POSIXct(date_stop, origin="1970-01-01", format="%Y-%m-%d  %H:%M", tz="GMT"))

# Timeline: activity per person 
people %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=date, y=person, group=person, color=activity), alpha=0.9)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=person, group=person, color=activity),
                     size= 1.5*ggplot2::.pt*72.27/96, lineend = "butt", alpha=0.85)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=person, group=person, color=activity, alpha=status), 
                     size= 1.5*ggplot2::.pt*72.27/96, lineend = "butt", show.legend = F)+
  ggplot2::geom_text(
    data = . %>% dplyr::filter(status==1, hour<18) %>% dplyr::arrange(date) %>% dplyr::distinct(date, person),
    ggplot2::aes(x=dplyr::last(date), y=person, group=person), label="Infected", size=3, hjust=0, color="red", check_overlap = T)+
  ggplot2::geom_segment(data = departments, ggplot2::aes(x=date_start, y=start, xend=date_start, yend=stop))+
  ggplot2::geom_point(data = departments, ggplot2::aes(x=date_start, y=start), shape=22)+
  ggplot2::geom_point(data = departments, ggplot2::aes(x=date_start, y=stop), shape=22)+
  ggplot2::geom_text(data = departments, ggplot2::aes(x=date_start, y=(start + stop) / 2, label=department),
                     hjust=-0.1, size=3)+
  ggplot2::geom_segment(data = departments, ggplot2::aes(x=date_start, y=start, xend=date_stop, yend=start),
                        size=0.5, linetype="dotted")+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+#, limits=date_limits)+
  ggplot2::scale_y_continuous(n.breaks = 8, expand=c(0,1), position = "right")+
  # ggplot2::ggtitle("Timeline of activities of each person",
  #                  "Each point indicates when a person does a certain activity. The Person ID is just a number assigned to each person")+
  ggplot2::labs(x=NULL, y="Person ID", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
  )


# ggplot2::ggsave(file.path(experiment, "timeline_activity_person.pdf"), width=6, height=6, device = cairo_pdf)

# Activity distribution per time
people %>% 
  dplyr::filter(activity != "home") %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(ggplot2::aes(x=date, y=forcats::fct_rev(activity), fill=activity), 
                                alpha=0.8, color=NA, stat = "binline", binwidth=15*60, scale=1,)+
  # ggridges::geom_density_ridges(ggplot2::aes(x=date, y=activity, fill=activity), 
  #                               alpha=0.8, bandwidth=15*60)+
  ggridges::geom_density_ridges(ggplot2::aes(x=date, y=forcats::fct_rev(activity), fill=activity), 
                                alpha=0.8, bandwidth=15*60, scale=1, 
                                jittered_points=T, point_shape = '|', point_size=1, point_alpha=0.5,
                                position = ggridges::position_points_jitter(width=5*60, height=0, yoffset = -0.1), show.legend = F )+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M")+#, expand=c(0,0))+
  ggplot2::theme_bw()+
  # ggplot2::ggtitle("Activity distribution per time",
  #                  "When each activity happens during the day. It must resemble the input schedule.\nFor example, lunch happens around noon.")+
  ggplot2::labs(x=NULL, y="Activity Event Density", fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(nrow=1))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=0, hjust=0.5),
  )

# ggplot2::ggsave(file.path(experiment, "timeline_activity_density.pdf"), width=6, height=6, device = cairo_pdf)

# Circular activity distribution per time
date_limits_polar <- lubridate::hm(c("07:00", "18:00")) %>% as.POSIXct(origin="1970-01-01", tz="GMT")
date_breaks <- lubridate::hm(paste0(seq(7,18), ":00")) %>% as.POSIXct(origin="1970-01-01", tz="GMT")
library(ggridges)
people %>% 
  dplyr::filter(activity != "home") %>% 
  ggplot2::ggplot()+
  # ggridges::geom_density_ridges(ggplot2::aes(x=date, y=activity, fill=activity), 
  #                               alpha=0.8, color=NA, stat = "binline", binwidth=5*60, show.legend = F)+
  ggridges::geom_density_ridges(ggplot2::aes(x=date, y=activity, fill=activity, height=..ndensity..),
                                scale=0.8, alpha=0.8, bandwidth=5*60, 
                                color="black", size=0.3, na.rm = T, show.legend = F)+
  # ggplot2::geom_density(ggplot2::aes(x=date, y=..scaled.., fill=activity), color=NA, alpha=0.2)+
  ggplot2::geom_vline(xintercept = c(4.5,7.75)*60*60, color="black", linetype="dotted", size=0.4)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_x_datetime(breaks = date_breaks, date_labels = "%H:%M",
                            limits = date_limits_polar,
                            expand = ggplot2::expansion(add=c(1*60*60,1*60*60)),
  )+
  ggplot2::scale_y_discrete(limits= c(NA, "coffee", "lunch", "meeting", "restroom","work") )+
  ggplot2::coord_polar()+
  ggplot2::labs(x=NULL, y=NULL, fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(override.aes = list(alpha=1)))+
  # ggplot2::theme_bw()+
  ggpubr::theme_pubclean(base_family = "Exo")+
  ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = "transparent"), 
    plot.background = ggplot2::element_rect(fill = "transparent", color = NA), 
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=12),
    # legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "left",
    # legend.key.size = grid::unit(4, "mm"),
    # legend.justification = "left",
    panel.grid.major.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
  ) -> g

# ggplot2::ggsave(g, filename = file.path(experiment, "schedule.pdf"), device = cairo_pdf, width = 6, height = 6, units = "in", bg = "transparent")
# cowplot::get_legend(g) %>% cowplot::ggdraw() %>%  ggplot2::ggsave(filename=file.path(experiment, "legend.pdf"), device = cairo_pdf, width=1, height = 2, units="in")

# ggplot2::ggsave(g, filename = file.path(experiment, "schedule.svg"), width = 6, height = 6, units = "in",bg = "transparent")
# cowplot::get_legend(g) %>% cowplot::ggdraw() %>%  ggplot2::ggsave(filename=file.path(experiment, "legend.svg"), width=1, height = 2, units="in")

# ggplot2::ggsave(g, filename = file.path(experiment, "schedule.png"), width = 6, height = 6, units = "in",bg = "transparent")
# cowplot::get_legend(g) %>% cowplot::ggdraw() %>%  ggplot2::ggsave(filename=file.path(experiment, "legend.png"), width=1, height = 2, units="in")


# PERSON ------------------------------------------------------------------

# Timeline: CO2 per person
people %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=date, y=quanta_inhaled, color=activity, group=person), alpha=0.1)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=CO2_level, color=activity, group=person), alpha=0.2)+
  ggplot2::geom_line(data = . %>% dplyr::filter(status==1),
                     ggplot2::aes(x=date, y=CO2_level, group=person), color="red", linetype="dotted", alpha=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M", limits=date_limits)+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Timeline of risk of each person",
                   "Each person starts with null risk, and this increases along the day. Each line represent a person.\nAs more places are visited, more risk a person has, subject to the air quality inside the room and the mask efficiency")+
  ggplot2::labs(x="Time", y="CO2 ppm", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=0, hjust=0.5),
  )

# Timeline: quanta per person
people %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=date, y=quanta_inhaled, color=activity, group=person), alpha=0.1)+
  ggplot2::geom_line(data = . %>% dplyr::filter(status==1),
                     ggplot2::aes(x=date, y=quanta_inhaled, group=person), 
                     color="red", linetype="dotted", alpha=1, size=1)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=quanta_inhaled, color=activity, group=person), alpha=0.5)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 10)+
  ggplot2::theme_bw()+
  # ggplot2::ggtitle("Timeline of CO2 of each person",
  #                  "Each person starts with null risk, and this increases along the day. Each line represent a person.\nAs more places are visited, more risk a person has, subject to the air quality inside the room and the mask efficiency")+
  ggplot2::labs(x=NULL, y="Quanta Inhaled (quanta)", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1, 0.8),
    legend.justification = "left",
    legend.direction = "vertical",
    legend.background = ggplot2::element_rect(fill = "transparent"),
    axis.text.x = ggplot2::element_text(angle=0, hjust=0.5),
  )

# ggplot2::ggsave(file.path(experiment, "timeline_person_quanta.pdf"), width=6, height=6, device = cairo_pdf)


# Timeline: risk per person 
people %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=date, y=infection_risk, color=activity, group=person), alpha=0.1)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=infection_risk, color=activity, group=person), alpha=0.2)+
  ggplot2::geom_line(data = . %>% dplyr::filter(status==1),
                     ggplot2::aes(x=date, y=infection_risk, group=person), color="red", linetype="dotted", alpha=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M", limits=date_limits)+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Timeline of risk of each person",
                   "Each person starts with null risk, and this increases along the day. Each line represent a person.\nAs more places are visited, more risk a person has, subject to the air quality inside the room and the mask efficiency")+
  ggplot2::labs(x="Time", y="Infection Risk", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
    axis.text.x = ggplot2::element_text(angle=0, hjust=0.5),
  )



# Distribution: final quanta inhaled per person
people %>% 
  # dplyr::filter(status == 0) %>%
  dplyr::group_by(name) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(
    status = unique(status),
    quanta_inhaled_max = max(quanta_inhaled, na.rm=T)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(y = quanta_inhaled_max) %>% 
  dplyr::arrange(y) %>% 
  dplyr::mutate(id = dplyr::row_number()) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_text(ggplot2::aes(x = 1, y=mean(y)), label=latex2exp::TeX('$\\mu$'),
                     color="blue", vjust=-0.5, hjust=0, check_overlap = T)+
  ggplot2::geom_text(ggplot2::aes(x = 1, y=mean(y)+sd(y)), label=latex2exp::TeX('$\\mu + \\sigma$'),
                     color="blue", vjust=-0.5, hjust=0, check_overlap = T)+
  ggplot2::geom_text(ggplot2::aes(x = 1, y=mean(y)-sd(y)), label=latex2exp::TeX('$\\mu - \\sigma$'),
                     color="blue", vjust=-0.5, hjust=0, check_overlap = T)+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(y)), color="blue", size=0.5, linetype="dashed")+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(y)+sd(y)), color="blue", size=0.5, linetype="dashed")+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(y)-sd(y)), color="blue", size=0.5, linetype="dashed")+
  ggplot2::geom_line(ggplot2::aes(x=id, y=y), alpha=1, na.rm=T)+
  ggplot2::geom_point(ggplot2::aes(x=id, y=y), alpha=0.5, na.rm=T)+
  ggplot2::geom_point(data = . %>% dplyr::filter(status == 1), 
                      ggplot2::aes(x=id, y=y), alpha=0.5, color="red",  size=3, na.rm=T)+
  # ggplot2::ggtitle("Risk at the end of the day of each person",
  #                  "Related to the previous plot, it is the value of each line at the end of the day (rightmost point)\nPeople are reorganized in increased order of risk")+
  ggplot2::labs(x="Person ID (ordered by quanta inhaled)", y="max. Quanta inhaled per person")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::scale_x_continuous(n.breaks = 8)+
  ggplot2::scale_y_continuous(n.breaks = 10, limits=c(0,NA), expand=c(0.05,-0.005), position = "right")+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
  )

# ggplot2::ggsave(file.path(experiment, "distribution_person_quanta.pdf"), width=6, height=6, device = cairo_pdf)

# quanta inhaled aggregated by department/building
people %>% 
  dplyr::group_by(name, department) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(quanta_inhaled_max = max(quanta_inhaled, na.rm=T), .groups = "keep") %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggplot2::geom_violin(ggplot2::aes(x=department, y=quanta_inhaled_max), 
                       scale = "width", width=0.7, color="gray90", trim=F, bw=0.01)+
  ggplot2::geom_boxplot(ggplot2::aes(x=department, y=quanta_inhaled_max), fill=NA, outlier.color = NA, width=0.7)+
  ggplot2::theme_bw()+
  # ggplot2::ggtitle("Risk at the end of the day of each, aggregated by department",
  #                  "Related to the previous plot, people are grouped by department, and the distribution of the risk is visualized here")+
  ggplot2::labs(x=NULL, y="max. Quanta inhaled per person")+  
  ggplot2::scale_y_continuous(n.breaks = 8, limits=c(0,NA))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    axis.text.x = ggplot2::element_text(angle=20, hjust=1, vjust=1)
  )

# ggplot2::ggsave(file.path(experiment, "boxplot_person_quanta.pdf"), width=6, height=4, device = cairo_pdf)


# Risk aggregated by department/building
people %>% 
  dplyr::group_by(name, building) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(quanta_inhaled_max = max(quanta_inhaled, na.rm=T), .groups = "keep") %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=building, y=quanta_inhaled_max), outlier.color = NA)+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Risk at the end of the day of each, aggregated by building",
                   "Related to the previous plot, people are grouped by building, and the distribution of the risk is visualized here")+
  ggplot2::labs(x="Building", y="Risk")+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
  )

# PLACE ------------------------------------------------------------------

# Timeline: CO2 per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=CO2_level, color=activity, group=name), alpha=0.5)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=CO2_level, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 8)+
  # ggplot2::facet_grid(cols=dplyr::vars(name), )
  # ggplot2::ggtitle("Timeline: air quality at each place",
  #                  "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x=NULL, y=latex2exp::TeX("$CO_2\\, level \\,(ppm)$"), color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent")
  )

# ggplot2::ggsave(file.path(experiment, "timeline_place_CO2.pdf"), width=6, height=6, device = cairo_pdf)


# Boxplot: CO2 per place
places %>% 
  dplyr::filter(activity!="home") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_violin(ggplot2::aes(x=name, y=CO2_level), 
                       scale = "width", width=0.7, color="gray90", trim=T, bw=50)+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=CO2_level, color=activity), fill=NA, outlier.color = NA, na.rm=T)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_y_continuous(n.breaks = 8, expand=c(0,20), position="right")+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  # ggplot2::ggtitle("Air Quality per place",
  #                  "Distribution of air quality along the day, for each place. This represents the most 'dirty' places")+
  ggplot2::labs(x=NULL, y=latex2exp::TeX("$CO_2\\, level \\,(ppm)$"), color="Activity", fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0.05), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent"),
    axis.text.x = ggplot2::element_text(angle=25, hjust=1, vjust=1)
  )

# ggplot2::ggsave(file.path(experiment, "boxplot_place_CO2.pdf"), width=9, height=6, device = cairo_pdf)


# Timeline: quanta per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=quanta_level, color=activity, group=name), alpha=0.5)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=quanta_level, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 7)+
  # ggplot2::facet_grid(cols=dplyr::vars(name), )
  # ggplot2::ggtitle("Timeline: air quality at each place",
  #                  "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x=NULL, y=latex2exp::TeX("$Quanta \\, level \\, (quanta)$"), color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent")
  )

# ggplot2::ggsave(file.path(experiment, "timeline_place_quanta.pdf"), width=6, height=6, device = cairo_pdf)


# Boxplot: quanta per place
places %>% 
  dplyr::filter(activity!="home") %>% 
  # dplyr::filter(quanta_level>0) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_violin(ggplot2::aes(x=name, y=quanta_level), 
                       scale = "width", width=0.7, color="gray90", trim=T, bw=0.01)+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=quanta_level, color=activity), fill=NA, outlier.color = NA, na.rm=T)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_y_continuous(n.breaks = 7, expand=c(0,0.002), position="right")+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  # ggplot2::ggtitle("Air Quality per place",
  #                  "Distribution of air quality along the day, for each place. This represents the most 'dirty' places")+
  ggplot2::labs(x=NULL, y=latex2exp::TeX("$Quanta\\, level \\,(quanta)$"), color="Activity", fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0.05), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent"),
    axis.text.x = ggplot2::element_text(angle=25, hjust=1, vjust=1)
  )

# ggplot2::ggsave(file.path(experiment, "boxplot_place_quanta.pdf"), width=9, height=6, device = cairo_pdf)

# Scatterplot: Quanta vs CO2
places %>% 
  dplyr::filter(name != "home") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_point(
    ggplot2::aes(x=CO2_level, y=quanta_level, color=(infective_people)),
    alpha=.5, shape=16, size=1)+
  ggplot2::facet_wrap(.~name, scales = "fixed", ncol=7)+
  ggplot2::scale_color_viridis_c()+
  ggplot2::guides(fill=ggplot2::guide_legend(override.aes = list(alpha=1)))+
  ggplot2::labs(x=latex2exp::TeX("$max \\, CO_2 \\, (ppm)$"), 
                y=latex2exp::TeX("$max \\, Quanta \\, (ppm)$"), 
                fill="Experiment")+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = "top",
    legend.justification = "left",
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside"
  )



# Timeline: temperature per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=temperature, color=activity, group=name), alpha=0.5)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=temperature, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 7)+
  # ggplot2::facet_grid(cols=dplyr::vars(name), )
  # ggplot2::ggtitle("Timeline: air quality at each place",
  #                  "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x=NULL, y="Temperature (ºC)", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent")
  )

# ggplot2::ggsave(file.path(experiment, "timeline_place_temperature.pdf"), width=6, height=6, device = cairo_pdf)


# Boxplot: temperature per place
places %>% 
  dplyr::filter(activity!="home") %>% 
  # dplyr::filter(quanta_level>0) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_violin(ggplot2::aes(x=name, y=temperature), 
                       scale = "width", width=0.7, color="gray90", trim=T, bw=0.01)+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=temperature, color=activity), fill=NA, outlier.color = NA, na.rm=T)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_y_continuous(n.breaks = 7, expand=c(0,0.002), position="right")+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  # ggplot2::ggtitle("Air Quality per place",
  #                  "Distribution of air quality along the day, for each place. This represents the most 'dirty' places")+
  ggplot2::labs(x=NULL, y="Temperature (ºC)", color="Activity", fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0.05), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent"),
    axis.text.x = ggplot2::element_text(angle=25, hjust=1, vjust=1)
  )

# ggplot2::ggsave(file.path(experiment, "boxplot_place_temperature.pdf"), width=9, height=6, device = cairo_pdf)


# Timeline: relative_humidity per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=relative_humidity, color=activity, group=name), alpha=0.5)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=relative_humidity, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M")+
  ggplot2::scale_y_continuous(n.breaks = 7)+
  # ggplot2::facet_grid(cols=dplyr::vars(name), )
  # ggplot2::ggtitle("Timeline: air quality at each place",
  #                  "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x=NULL, y="Relative Humidity (%)", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::coord_cartesian(xlim = date_limits)+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent")
  )

# ggplot2::ggsave(file.path(experiment, "timeline_place_relative_humidity.pdf"), width=6, height=6, device = cairo_pdf)


# Boxplot: relative_humidity per place
places %>% 
  dplyr::filter(activity!="home") %>% 
  # dplyr::filter(quanta_level>0) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_violin(ggplot2::aes(x=name, y=relative_humidity), 
                       scale = "width", width=0.7, color="gray90", trim=T, bw=0.01)+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=relative_humidity, color=activity), fill=NA, outlier.color = NA, na.rm=T)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_y_continuous(n.breaks = 7, expand=c(0,0.002), position="right")+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  # ggplot2::ggtitle("Air Quality per place",
  #                  "Distribution of air quality along the day, for each place. This represents the most 'dirty' places")+
  ggplot2::labs(x=NULL, y="Relative Humidity (%)", color="Activity", fill="Activity")+
  ggplot2::guides(fill = ggplot2::guide_legend(ncol=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggpubr::theme_pubclean()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0.05), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = c(0.1,0.8),
    legend.justification = "left",
    legend.background = ggplot2::element_rect(fill = "transparent"),
    axis.text.x = ggplot2::element_text(angle=25, hjust=1, vjust=1)
  )

# ggplot2::ggsave(file.path(experiment, "boxplot_place_relative_humidity.pdf"), width=9, height=6, device = cairo_pdf)



# OTHER TIMELINES -------------------------------------------------------------------

# Timeline: place per person
people %>% 
  ggplot2::ggplot()+
  ggplot2::geom_point(ggplot2::aes(x=time, y=place, group=person, color=activity), alpha=0.9)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::ggtitle("Timeline: events at each place",
                   "Each point represents an event at a certain place")+
  ggplot2::labs(x="Date", y="Place", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
  )

# Timeline: number people at each activity
# places %>%
#   ggplot2::ggplot()+
#   ggplot2::geom_line(ggplot2::aes(x=time, y=num_people, color=activity, group=name), alpha=0.9)+
#   ggplot2::scale_color_manual(values=palette)+
#   ggplot2::theme_bw()

# Timeline: number people at each place (per activity)
places %>% 
  dplyr::arrange(date) %>%
  ggplot2::ggplot()+
  ggplot2::geom_step(ggplot2::aes(x=date, y=num_people, color=activity, group=name), alpha=0.9)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=num_people, color=activity, group=name), alpha=0.9, size=1)+
  ggplot2::facet_grid(rows=dplyr::vars(activity), scales="free")+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M", limits=date_limits)+
  ggplot2::scale_y_continuous(limits=c(0,NA))+
  ggplot2::ggtitle("Timeline: number of people at each place",
                   "Each line represents a place of certain activity (color) and the y-axis indicates the number of people in that place")+
  ggplot2::labs(x="Date", y="# People", color="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(nrow=1, override.aes = list(alpha = 1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.title = ggplot2::element_text(size=10),
    legend.margin= ggplot2::margin(c(0,0,0,0)),
    legend.position = "top",
    legend.justification = "left",
  )




# HISTOGRAM ---------------------------------------------------------------

# Histogram: number people at each place
# places %>% 
#   ggplot2::ggplot()+
#   ggplot2::geom_histogram(ggplot2::aes(x=num_people, fill=activity, group=activity), alpha=0.9, binwidth=1)+
#   ggplot2::facet_wrap(.~name, ncol = 6, scales = "free")+
#   ggplot2::scale_fill_manual(values=palette)+
#   ggplot2::theme_bw()

places %>% 
  dplyr::filter(activity != "home") %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(ggplot2::aes(x=num_people, y=name, fill=activity), 
                                rel_min_height = 0.05, color="black", alpha=0.6,
                                scale=1, stat = "binline", binwidth=1, na.rm=T)+
  ggplot2::geom_point(data = places_info, ggplot2::aes(x=capacity, y=name),
                      shape=124, size=5, color="red", na.rm=T)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Histogram: number of people per place",
                   "How many people are at a given place. The red line indicates the maximum allowed capacity of each place")+
  ggplot2::labs(x="# People", y="Place", fill="Activity")

# Histogram: occupancy at each place
# places %>% 
#   dplyr::mutate(occupancy = num_people / capacity) %>% 
#   ggplot2::ggplot()+
#   ggplot2::geom_histogram(ggplot2::aes(x=occupancy, fill=activity, group=activity), alpha=0.9, binwidth=0.05, na.rm=T)+
#   ggplot2::facet_wrap(.~name, ncol = 6, scales = "fixed")+
#   ggplot2::scale_x_continuous(n.breaks=3)+
#   ggplot2::scale_fill_manual(values=palette)+
#   ggplot2::theme_bw()


# places %>% 
#   dplyr::mutate(occupancy = num_people / capacity) %>% 
#   ggplot2::ggplot()+
#   ggridges::geom_density_ridges(
#     stat="binline", binwidth=0.01,
#     ggplot2::aes(x=occupancy, y=name, fill=activity), color="black",
#     # bandwidth = 0.01, rel_min_height=0.01,
#     alpha=0.6, scale=2, na.rm=T)+
#   ggplot2::scale_fill_manual(values=palette)+
#   ggplot2::theme_bw()+
#   ggplot2::ggtitle("Occupancy per place")+
#   ggplot2::labs(x="Occupancy", y="Place", fill="Activity")


places %>% 
  dplyr::mutate(occupancy = num_people / capacity) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=occupancy, fill=activity), outlier.color = NA, na.rm=T)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  ggplot2::ggtitle("Occupancy per place",
                   "How many people are at each place, relative to its maximum allowed capacity")+
  ggplot2::labs(x="Place", y="Occupancy", fill="Activity")


# Histogram: air quality at each place
# places %>% 
#   ggplot2::ggplot()+
#   ggridges::geom_density_ridges(
#     stat="binline", 
#     ggplot2::aes(x=air_quality, y=name, fill=activity), 
#     # bandwidth = 0.1, rel_min_height=0.001, 
#     scale=3, 
#     color="black", alpha=0.6, na.rm=T)+
#   ggplot2::scale_fill_manual(values=palette)+
#   ggplot2::theme_bw()

dev.off()


# -------------------------------------------------------------------------

library(magrittr)

colors <- c("#00FF00","#FF0000")
id <- c("open_office", "it_office", "chief_office_A", "chief_office_B", "chief_office_C", 
        "meeting_A", "meeting_B", "meeting_C", "meeting_D", 
        "coffee_A", "coffee_B", "restroom_A", "restroom_B", "lunch")
# value <- seq(1,14)
# data <- data.frame(id, value, stringsAsFactors = F) %>% 
#   dplyr::mutate(fill = colorRampPalette(colors)(max(value)-min(value)+1)[value-min(value)+1])

data <- places %>% 
  dplyr::filter(run == 0) %>% 
  dplyr::group_by(name) %>% 
  dplyr::summarise(
    CO2_level_max = max(CO2_level, na.rm=T),
    quanta_level_max = max(quanta_level, na.rm=T)
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::select(id=name, value=quanta_level_max) %>% 
  dplyr::mutate(
    value_backup = value,
    value = value * 10000,
    fill = colorRampPalette(colors)(max(value)-min(value)+1)[value-min(value)+1])

g <- data %>% 
  ggplot2::ggplot()+
  ggplot2::geom_point(ggplot2::aes(x=id, y=value, color=value_backup))+
  ggplot2::scale_color_gradient(low = colors[1], high = colors[2], n.breaks=10)+
  # ggplot2::labs(color=latex2exp::TeX("$CO_2 \\, level$"))+
  ggplot2::labs(color=latex2exp::TeX("$quanta \\, level$"))+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
    legend.key.height = grid::unit(1, "cm"),
    legend.title = ggplot2::element_text(size=12),
    legend.margin= ggplot2::margin(c(0,0,0,0))
  )

ggpubr::get_legend(g) %>% ggpubr::as_ggplot() 
# ggplot2::ggsave(file.path(experiment, "floorplan_legend_CO2.pdf"), width=2, height=3, device = cairo_pdf)
# ggplot2::ggsave(file.path(experiment, "floorplan_legend_quanta.pdf"), width=2, height=3, device = cairo_pdf)


xml <- XML::xmlParse("floorplan/floorplan.svg") %>% XML::xmlRoot()

replace_fill <- function(xml, id, fill){
  xml[["g"]] %>% 
    XML::xmlChildren(addNames = F) %>% 
    lapply(function(child){
      attributes <- child %>% XML::xmlAttrs()
      if(attributes[["id"]] == id){
        attributes[["style"]] <- stringr::str_replace(string = attributes[["style"]], pattern = "none", replacement = fill)
        XML::xmlAttrs(child) <- attributes
      }
      return(child)
    })
  xml
}
tmp <- apply(data, 1, function(row){
  xml <- replace_fill(xml, row["id"], row["fill"])
})

XML::saveXML(xml, file = file.path(experiment, "floorplan_heatmap.svg"))

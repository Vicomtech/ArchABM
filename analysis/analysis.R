library(magrittr)


# IMPORT ------------------------------------------------------------------

experiments <- list.files(path = "../results", full.names = T)
n <- length(experiments)

experiment <- experiments[n]

config_file <- file.path(experiment, "config.json")
places_file <- file.path(experiment, "places.csv")
people_file <- file.path(experiment, "people.csv")


print(experiment)
config <- jsonlite::fromJSON(config_file)
places <- read.csv(places_file)
people <- read.csv(people_file)

places_info <- config$Places %>% 
  tibble::rowid_to_column(var = "place") %>% 
  dplyr::mutate(place = place-1)

people_info <- config$People %>% 
  tibble::rowid_to_column(var = "person") %>% 
  dplyr::mutate(person = person-1)

places <- merge(places, places_info, by = "place", sort = F)
people <- merge(people, people_info, by = "person", sort=F)

# COLOR PALETTE
values <- places_info$activity %>% unique() %>% sort()
palette <- c("#BF506E", "#34B1BF", "#89BF7A", "#571FA6", "#9cadbc", "#F2B950")
names(palette) <- values
# scales::show_col(palette)



# DATA VIZ ----------------------------------------------------------------

pdf(file.path(experiment, "results.pdf"), 10, 7)



# COUNTS ------------------------------------------------------------------


# Count: number events at each place
places %>% 
  dplyr::group_by(name, activity) %>% 
  dplyr::summarise(num_events=dplyr::n()) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggplot2::geom_col(ggplot2::aes(x=name, y=num_events, fill=activity), alpha=0.9, width=0.6)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  ggplot2::ggtitle("[V] Number of events per place", 
                   "Count number of events that happen at each place. \nFor example, most frequent places are related to work activity")+
  ggplot2::labs(x="Place", y="# Events", fill="Activity")

people %>% 
  merge(config$Events, by="activity") %>% 
  dplyr::add_count(name, activity, name = "count") %>% 
  # dplyr::mutate(repeat_max = ifelse(is.na(repeat_max), max(count), repeat_max)) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_jitter(ggplot2::aes(x=activity, y=count, color=activity), width = 0.1, height=0.2, alpha=0.1)+
  ggplot2::geom_text(ggplot2::aes(x=activity, y=repeat_max, label="MAX"), 
                     color = "red", fontface="bold", check_overlap = T, na.rm=T, nudge_x = -0.3, nudge_y=0.5)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, repeat_max),
                      ggplot2::aes(x=activity, y=repeat_max), color = "red", fill="red", shape=25, na.rm=T)+
  ggplot2::geom_text(ggplot2::aes(x=activity, y=repeat_min, label="MIN"), 
                     color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=-0.5)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, repeat_min),
                      ggplot2::aes(x=activity, y=repeat_min), color = "red", fill="red", shape=24)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  ggplot2::ggtitle("[V] Number of events per person",
                   "Count number of activities each person does. Repeat min/max are included as reference in red color.\nGives an idea of how many times each person repeats an activity")+
  ggplot2::labs(x="Activity", y="# Events per person", fill="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(alpha = 1)))



people %>% 
  merge(config$Events, by="activity") %>%
  dplyr::group_by(name) %>% 
  dplyr::arrange(time) %>% 
  dplyr::mutate(elapsed = dplyr::lead(time)-time) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_jitter(ggplot2::aes(x=activity, y=elapsed, color=activity), width = 0.1, alpha=0.1, na.rm=T)+
  ggplot2::geom_text(ggplot2::aes(x=activity, y=duration_max, label="MAX"), 
                     color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=10)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, duration_max),
                      ggplot2::aes(x=activity, y=duration_max), color = "red", fill="red", shape=25)+
  ggplot2::geom_text(ggplot2::aes(x=activity, y=duration_min, label="MIN"), 
                     color = "red", fontface="bold", check_overlap = T, nudge_x = -0.3, nudge_y=-10)+
  ggplot2::geom_point(data = . %>% dplyr::distinct(activity, duration_min),
                      ggplot2::aes(x=activity, y=duration_min), color = "red", fill="red", shape=24)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  ggplot2::ggtitle("[V] Duration of events per person",
                   "How much time each person stays in the same place doing an activity. Duration min/max are included as reference in red color\nIt is possible to exceed these limits, since a person can stay in the same place for multiple consecutive events")+
  ggplot2::labs(x="Activity", y="# Duration of events per person", fill="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(alpha = 1)))


# TIMELINE ----------------------------------------------------------------

# Timeline: activity per person 
people %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M")
  ) %>%
  ggplot2::ggplot()+
  ggplot2::geom_point(ggplot2::aes(x=date, y=person, group=person, color=activity), alpha=0.9)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("[V] Timeline of activities of each person",
                   "Each point indicates when a person does a certain activity. The Person ID is just a number assigned to each person")+
  ggplot2::labs(x="Date", y="Person ID", fill="Activity")

# Activity distribution per time
people %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M")
  ) %>%
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(ggplot2::aes(x=date, y=activity, fill=activity), alpha=0.8, bandwidth=15*60)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Activity distribution per time",
                   "When each activity happens during the day. It must resemble the input schedule.\nFor example, lunch happens around noon.")+
  ggplot2::labs(x="Date", y="Activity", fill="Activity")


# Timeline: risk per person 
people %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M")
  ) %>%
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=date, y=risk, color=activity, group=person), alpha=0.1)+
  ggplot2::geom_line(ggplot2::aes(x=date, y=risk, color=activity, group=person), alpha=0.2)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Timeline of risk of each person",
                   "Each person starts with null risk, and this increases along the day. Each line represent a person.\nAs more places are visited, more risk a person has, subject to the air quality inside the room and the mask efficiency")+
  ggplot2::labs(x="Date", y="Risk", fill="Activity")+
  ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(alpha = 1)))



people %>% 
  dplyr::group_by(name) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(final_risk = dplyr::last(risk),
                color = cut(final_risk, c(80,90,100,110))
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(final_risk) %>% 
  dplyr::mutate(id = dplyr::row_number()) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(final_risk)), color="blue", size=1, linetype="dashed")+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(final_risk)+sd(final_risk)), color="blue", size=0.5, linetype="dashed")+
  ggplot2::geom_hline(ggplot2::aes(yintercept=mean(final_risk)-sd(final_risk)), color="blue", size=0.5, linetype="dashed")+
  ggplot2::geom_line(ggplot2::aes(x=id, y=final_risk), alpha=1, na.rm=T)+
  ggplot2::geom_point(ggplot2::aes(x=id, y=final_risk), alpha=0.5, na.rm=T)+
  ggplot2::theme_bw()+
  # ggplot2::theme(axis.text.x = ggplot2::element_blank())+
  ggplot2::ggtitle("Risk at the end of the day of each person",
                   "Related to the previous plot, it is the value of each line at the end of the day (rightmost point)\nPeople are reorganized in increased order of risk")+
  ggplot2::labs(x="Person ID (unordered)", y="Risk")

# Risk aggregated by department/building
people %>% 
  dplyr::group_by(name, department) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(final_risk = dplyr::last(risk)) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=department, y=final_risk))+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Risk at the end of the day of each, aggregated by department",
                   "Related to the previous plot, people are grouped by department, and the distribution of the risk is visualized here")+
  ggplot2::labs(x="Person ID (unordered)", y="Risk")

people %>% 
  dplyr::group_by(name, building) %>% 
  dplyr::arrange(time) %>% 
  dplyr::summarise(final_risk = dplyr::last(risk)) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=building, y=final_risk))+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Risk at the end of the day of each, aggregated by building",
                   "Related to the previous plot, people are grouped by building, and the distribution of the risk is visualized here")+
  ggplot2::labs(x="Person ID (unordered)", y="Risk")


# Timeline: air quality at each place
places %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M")
  ) %>%
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=air_quality, color=activity, group=name), alpha=0.9)+
  ggplot2::geom_point(ggplot2::aes(x=date, y=air_quality, color=activity, group=name), alpha=0.9)+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Timeline: air quality at each place",
                   "Each line represents a place of certain activity (color) and the y-axis indicates the air quality in that place.\nNote that if nobody is present in a place, the air quality of the room improves (ventilation rate)")+
  ggplot2::labs(x="Date", y="Air Quality", fill="Activity")


# Timeline: place per person
# people %>% 
#   ggplot2::ggplot()+
#   ggplot2::geom_point(ggplot2::aes(x=time, y=place, group=person, color=activity), alpha=0.9)+
#   ggplot2::scale_color_manual(values=palette)+
#   ggplot2::theme_bw()

# air quality per place
places %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=name, y=air_quality, fill=activity), outlier.color = NA, na.rm=T)+
  ggplot2::scale_fill_manual(values=palette)+
  ggplot2::theme_bw()+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle=30, hjust=1))+
  ggplot2::ggtitle("Air Quality per place",
                   "Distribution of air quality along the day, for each place. This represents the most 'dirty' places")+
  ggplot2::labs(x="Place", y="Air Quality", fill="Activity")

# Timeline: number people at each activity
# places %>% 
#   ggplot2::ggplot()+
#   ggplot2::geom_line(ggplot2::aes(x=time, y=num_people, color=activity, group=name), alpha=0.9)+
#   ggplot2::scale_color_manual(values=palette)+
#   ggplot2::theme_bw()

# Timeline: number people at each place (per activity)
places %>% 
  dplyr::mutate(
    hour = floor(time/60),
    minutes = time %% 60,
    date = paste0("1970-01-01 ", hour , ":", minutes),
    date = as.POSIXct(date, origin="1970-01-01", format="%Y-%m-%d  %H:%M")
  ) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=date, y=num_people, color=activity, group=name), alpha=0.9)+
  ggplot2::facet_grid(rows=dplyr::vars(activity), scales="free")+
  ggplot2::scale_color_manual(values=palette)+
  ggplot2::scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")+
  ggplot2::theme_bw()+
  ggplot2::ggtitle("Timeline: number of people at each place",
                   "Each line represents a place of certain activity (color) and the y-axis indicates the number of people in that place")+
  ggplot2::labs(x="Date", y="# People", fill="Activity")




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
                                rel_min_height = 0.05, scale=2, bandwidth=1, color="black", alpha=0.6, na.rm=T)+
  ggplot2::geom_point(data = places_info, ggplot2::aes(x=capacity, y=name),
                      shape=124, size=5, color="red")+
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

# GRAPH -------------------------------------------------------------------

blacklist <- c("home")
blacklist <- c()

nodes <- places_info %>% 
  dplyr::filter(!(activity %in% blacklist)) %>% 
  merge(data.frame(activity=names(palette), color=palette, row.names = NULL), by="activity") %>%  
  dplyr::rename(id=place, label=name, group=activity, value=area) 

edges <- people %>% 
  dplyr::filter(!(activity %in% blacklist)) %>% 
  dplyr::group_by(person) %>% 
  dplyr::arrange(person, time) %>% 
  dplyr::mutate(
    from = place,
    to = dplyr::lead(place)
  ) %>% 
  dplyr::ungroup() %>% 
  na.omit() %>% 
  dplyr::group_by(from, to) %>% 
  dplyr::mutate(weight=dplyr::n()) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(from != to) %>% 
  dplyr::distinct(from, to, weight) %>%
  dplyr::rename(from=from, to=to, width=weight)


visNetwork::visNetwork(nodes, edges, width="100%", height = "800",
                       main = list(text="Interaction Graph", 
                                   style="font-family:Roboto;font-size:24px;text-align:center;")
) %>% 
  visNetwork::visNodes(shape="square", font=list(face="Roboto", size=30), 
                       scaling=list(min=10, max=40)) %>%
  visNetwork::visEdges(smooth=T, color=list(color="#848484", opacity=0.1)) %>%
  visNetwork::visPhysics(solver = "forceAtlas2Based", stabilization=T, minVelocity=3) %>%
  visNetwork::visInteraction(dragView = T, hideEdgesOnDrag = F, hover = T) %>% 
  # visNetwork::visIgraphLayout(layout = "layout_nicely") %>%
  # visNetwork::visLegend(position="right", zoom=F) %>% 
  visNetwork::visOptions(highlightNearest = list(enabled=T, degree=0, hover=T, 
                                                 hideColor="rgba(0,0,0,0)", labelOnly=T)) %>% 
  visNetwork::visLayout(randomSeed = 0) #%>% 
# visNetwork::visSave(file = "interaction.html", selfcontained = F)
# visNetwork::visSave(file = file.path(experiment, "interaction.html"), selfcontained = T)





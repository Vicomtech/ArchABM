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





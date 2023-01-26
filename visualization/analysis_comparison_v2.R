library(magrittr)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')
Sys.setenv(LANG = "en_US.UTF-8")
extrafont::loadfonts(quiet = T)

# IMPORT ------------------------------------------------------------------


experiments_path <- list.files(path = "../results/experiments/", full.names = T)
n <- length(experiments_path)
if(n == 0){
  stop("No experiments found")
}

get_experiment <- function(experiment_path){
  
  config_file <- file.path(experiment_path, "config.json")
  places_file <- file.path(experiment_path, "places.csv")
  people_file <- file.path(experiment_path, "people.csv")
  
  print(experiment_path)
  config <- jsonlite::fromJSON(config_file)
  places <- data.table::fread(places_file) %>% 
    dplyr::group_by(run, place) %>% 
    dplyr::mutate(
      CO2_level_delta = CO2_level - dplyr::lag(CO2_level, default=CO2_level[1]),
      quanta_level_delta = quanta_level - dplyr::lag(quanta_level, default=quanta_level[1]),
    ) %>% 
    dplyr::summarise(
      infective_people_mean = mean(infective_people, na.rm=T),
      CO2_level_max = max(CO2_level, na.rm=T),
      quanta_level_max = max(quanta_level, na.rm=T),
      CO2_level_delta_max = max(CO2_level_delta, na.rm=T),
      quanta_level_delta_max = max(quanta_level_delta, na.rm=T),
      .groups = "keep"
    ) %>%
    dplyr::ungroup()
  
  people <- data.table::fread(people_file) %>% 
    dplyr::mutate(infection_risk = 1 - exp(-quanta_inhaled)) %>% 
    dplyr::filter(status == 0) %>% 
    dplyr::group_by(run, person) %>% 
    dplyr::arrange(time) %>% 
    dplyr::mutate(
      elapsed = time - dplyr::lag(time, default = 0),
      quanta_inhaled_delta = quanta_inhaled - dplyr::lag(quanta_inhaled, default=quanta_inhaled[1]),
    ) %>%
    dplyr::summarise(
      CO2_level_mean = weighted.mean(CO2_level, elapsed, na.rm=T),
      quanta_inhaled_max = max(quanta_inhaled, na.rm=T),
      quanta_inhaled_delta_max = max(quanta_inhaled_delta, na.rm=T),
      .groups = "keep"
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
  # people <- merge(people, events_info, by = "event")
  
  return(list(config=config, places=places, places_info=places_info, people=people, people_info=people_info))
}

results <- lapply(experiments_path, get_experiment)

# EXPERIMENTS
experiment_name = c(
  "1. Baseline",
  "2. Larger building",
  "3. Separate\nworkspaces",
  "4. Better natural\nventilation",
  "5. Better mechanical\nventilation",
  "6. Working\nin shifts",
  "7. Limit events\nduration",
  "8. Wearing masks",
  "9. Better natural\nventilation + Limit\nevents duration"
)
experiment_df <- data.frame(experiment_name, stringsAsFactors = F) %>% tibble::rowid_to_column(var = "experiment_id")

# COLOR PALETTE
values <- results[[1]]$places_info$activity %>% unique %>% sort
palette_activity <- c("#BF506E", "#34B1BF", "#89BF7A", "#571FA6", "#9cadbc", "#F2B950")
names(palette_activity) <- values

palette_experiments <- ggsci::pal_d3()(9) %>% rev  # D3, IGV, NEJM
names(palette_experiments) <- experiment_name

# scales::show_col(palette_places)


# PLACES ----------------------------------------------------------------

places <- lapply(results, function(x) x$places) %>% 
  dplyr::bind_rows(.id = "experiment_id") %>% 
  merge(experiment_df, by="experiment_id") %>% 
  dplyr::mutate(
    experiment_id = as.numeric(experiment_id),
    name_ext = ifelse(stringr::str_detect(name, "open_office"), "open_office", name)
  ) %>% 
  dplyr::filter(name != "home") %>% 
  dplyr::filter(run <= 500)


## PLACES - METRICS ------------------------------------------------------

metrics <- c(
  "CO2_level_max", 
  "CO2_level_delta_max",
  "quanta_level_max",
  "quanta_level_delta_max"
)
metrics_labels <- c(
  "$max \\, CO_2 \\, (ppm)$", 
  "$max \\, \\Delta CO_2 \\, (ppm)$",
  "$max \\, Quanta \\, (quanta)$", 
  "$max \\, \\Delta Quanta \\, (quanta)$"
)
breaks <- list(
  c(500, 1000, 1500),
  c(0, 300, 600, 900),
  c(0.0,0.15,0.30),
  c(0.0,0.1,0.2,0.3)
)
limits <- list(
  c(400, 2000),
  c(400, 2000),
  c(0, 0.4),
  c(0, 0.4)
)
xloc <- c(2000, 0, 0.4, 0)
textloc <- c(1750, 0, 0.35, 0)
color_breaks <- list(
  c(-60,-30,0,30,60),
  c(-40,-20,0,20,40),
  c(-80,-40,0,40,80),
  c(-80,-40,0,40,80)
)
color_limits <- list(
  c(-60,60),
  c(-55,55),
  c(-80,80),
  c(-80,80)
)

i <- 3

baseline <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::filter(experiment_id == 1) %>%
  dplyr::select(-experiment_id, -experiment_name) %>%
  dplyr::bind_cols(experiment_df %>%
                     tidyr::pivot_wider(names_from = "experiment_id", values_from = "experiment_name")) %>%
  tidyr::pivot_longer(cols = experiment_df$experiment_id %>% as.character(),
                      names_to = "experiment_id", values_to = "experiment_name") %>% 
  dplyr::mutate(experiment_id = as.numeric(experiment_id))


normality <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::group_by(experiment_name, name_ext) %>%
  dplyr::sample_n(min(dplyr::n(), 5000)) %>% 
  rstatix::shapiro_test(x) %>%
  rstatix::add_significance(symbols = c("\u25E4\u25E4\u25E4\u25E4", "\u25E4\u25E4\u25E4", "\u25E4\u25E4", "\u25E4", "")) %>% 
  dplyr::mutate(normal = p > 0.05)

effect_size_normal <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, name_ext, x) %>% 
  merge(normality %>% dplyr::select(experiment_name, name_ext, normal)) %>% 
  dplyr::filter(normal) %>% 
  dplyr::group_by(experiment_name, name_ext) %>%
  rstatix::cohens_d(x ~ case, ref.group = "2", paired = F, var.equal = F) %>%
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

effect_size_nonnormal <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, name_ext, x) %>% 
  merge(normality %>% dplyr::select(experiment_name, name_ext, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::group_by(experiment_name, name_ext) %>%
  rstatix::wilcox_effsize(x ~ case, ref.group = "2", paired = F) %>%
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

effect_size <- rbind(effect_size_normal, effect_size_nonnormal)

ttest <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, name_ext, x) %>%
  merge(normality %>% dplyr::select(experiment_name, name_ext, normal)) %>% 
  dplyr::filter(normal) %>% 
  dplyr::group_by(experiment_name, name_ext) %>%
  rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

wilcoxtest <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  merge(normality %>% dplyr::select(experiment_name, name_ext, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::select(case, experiment_name, name_ext, x) %>%
  dplyr::group_by(experiment_name, name_ext) %>%
  rstatix::wilcox_test(x ~ case, ref.group = "2", paired = F, exact=F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

hypothesis_test <- rbind(
  ttest %>% dplyr::select(experiment_name, name_ext, method, estimate, statistic, p, p.signif), 
  wilcoxtest %>% dplyr::select(experiment_name, name_ext, method, estimate, statistic, p, p.signif))


significant <- merge(
  effect_size %>% dplyr::mutate(cond1 = magnitude %in% c("moderate", "large")),
  hypothesis_test %>% dplyr::mutate(cond2 = p < 1e-4),
  by=c("experiment_name", "name_ext")
) %>% 
  dplyr::mutate(cond = cond1 & cond2) %>%
  dplyr::select(experiment_name, name_ext, cond)

# density plot without colors
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  ggplot2::ggplot()+
  # BASELINE RIDGES
  ggridges::geom_density_ridges(
    data = baseline,
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.2, alpha=1.0, stat = "density", color="black", fill="gray90", linetype="dotted"
  )+
  # COLOR RIDGES
  ggridges::geom_density_ridges(
    data = . %>% dplyr::filter(experiment_id != 1),
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.5, alpha=0.1, stat = "density", show.legend = F, fill="gray90", color="black",
  )+
  # BASELINE CENTRAL MEASURE
  ggplot2::geom_segment(
    data = baseline %>% dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup(),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="gray50",
  )+
  # COLOR CENTRAL MEASURE
  ggplot2::geom_segment(
    data = . %>% dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="black",
  )+
  # SEGMENT DIFFERENCE
  ggplot2::geom_segment(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp1, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp2, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 color=diff_rel),
    size=2, lineend="butt", show.legend = T
  )+
  # TEXT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 > tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, color=diff_rel,
                 label=label), hjust=-0.1, size=2.5, fontface="bold"
  )+
  # SIGNIFICANT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 < tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      merge(significant, sort = F) %>% 
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, label=ifelse(cond, "\u2731", NA)), 
    color="#F06800", hjust=1.1, size=2.5, fontface="bold", na.rm=T
  )+
  # NORMALITY
  ggplot2::geom_text(
    data = normality,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.02, label=p.signif),
    color="black", fontface="bold", hjust=0, vjust=0.5, size=2.25, angle=90, check_overlap = F)+
  # HYPOTHESIS TEST DIFFERENCE
  ggplot2::geom_text(
    data = hypothesis_test,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.02, label=p.signif),
    color="gray50", fontface="bold", hjust=0, vjust=0.5, size=2.25, angle=90, check_overlap = F)+
  # EFFECT SIZE DIFFERENCE
  ggplot2::geom_text(
    data = effect_size,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.52, label=p.signif),
    color="black", fontface="bold", hjust=0.4, vjust=0.0, size=2.25, angle=0)+
  # # ANNOTATE
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_A") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Shapiro-Wilk\nNormality Test", color="black", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_A") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.1, size=0.25, color="black", 
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_B") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Welch / Mann–\nWhitney test", color="gray50", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_B") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.3, size=0.25, color="gray50"
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_C") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Cohen / Wilcoxon\nEffect Size", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(name_ext == "chief_office_C") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.5, size=0.25
  # )+
  ggplot2::facet_wrap(. ~ name_ext, scales="fixed", nrow=2)+
  ggplot2::scale_x_continuous(breaks = breaks[[i]], limits=limits[[i]])+
  ggplot2::scale_color_gradient2(low="#00F260", mid = "#0575E6", high = "#fc4a1a", midpoint = 0,
                                 breaks = color_breaks[[i]], limits=color_limits[[i]])+
  ggplot2::labs(x=latex2exp::TeX(metrics_labels[i]), y="Density", color="Mean Difference %")+
  ggplot2::guides(color = ggplot2::guide_colourbar(title.position = "top", title.hjust = 0.5))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.position = c(-0.012, -0.02),
    legend.direction = "horizontal",
    legend.key.height = ggplot2::unit(6, 'pt'),
    legend.key.width = ggplot2::unit(14, 'pt'),
    legend.justification = "right",
    legend.title = ggplot2::element_text(size=8),
    legend.text = ggplot2::element_text(size=8),
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(angle=0),
  ) -> g

ggplot2::ggsave("places_density_ridges.pdf", width=9, height=11.5, device = cairo_pdf)

### PLACES - INFECTION RISK vs CO2 ------------------------------------------

places %>% 
  # dplyr::filter(experiment_id %in% c(1)) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_point(
    ggplot2::aes(x=CO2_level_max, y=quanta_level_max, color=experiment_name),
    alpha=.5, shape=16, size=1)+
  ggplot2::facet_wrap(.~name_ext, scales = "fixed", ncol=7)+
  ggplot2::scale_color_manual(values=palette_experiments)+
  ggplot2::guides(color=ggplot2::guide_legend(override.aes = list(alpha=1, size=2), nrow = 1))+
  ggplot2::labs(x=latex2exp::TeX("$max \\, CO_2 \\, (ppm)$"), 
                y=latex2exp::TeX("$max \\, Quanta \\, (ppm)$"), 
                color="Experiment")+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = "top",
    legend.justification = "left",
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside"
  )

# PEOPLE ------------------------------------------------------------------

people <- lapply(results, function(x) x$people) %>%
  dplyr::bind_rows(.id = "experiment_id") %>% 
  merge(experiment_df, by="experiment_id") %>% 
  dplyr::mutate(experiment_id = as.numeric(experiment_id)) %>% 
  dplyr::filter(run <= 500)


## PEOPLE - METRICS --------------------------------------------------------

metrics <- c(
  "CO2_level_mean", 
  "quanta_inhaled_max"
)
metrics_labels <- c(
  "$mean \\, CO_2 \\, inhaled \\, (ppm)$", 
  "$max \\, Quanta \\, inhaled \\, (quanta)$" 
)
breaks <- list(
  c(400, 600, 800),
  c(0.0,0.1,0.2)
)
limits <- list(
  c(400, 1000),
  c(0, 0.3)
)
xloc <- c(1000, 0.3)
textloc <- c(1700, 0.35)
color_breaks <- list(
  c(-30,-15,0,15,30),
  c(-100,-50,0,50,100)
)
color_limits <- list(
  c(-30,30),
  c(-100,100)
)

i <- 2

baseline <- people %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::filter(experiment_id == 1) %>%
  dplyr::select(-experiment_id, -experiment_name) %>%
  dplyr::bind_cols(experiment_df %>%
                     tidyr::pivot_wider(names_from = "experiment_id", values_from = "experiment_name")) %>%
  tidyr::pivot_longer(cols = experiment_df$experiment_id %>% as.character(),
                      names_to = "experiment_id", values_to = "experiment_name") %>% 
  dplyr::mutate(experiment_id = as.numeric(experiment_id))


normality <- people %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::group_by(experiment_name, department) %>%
  dplyr::sample_n(min(dplyr::n(), 5000)) %>% 
  rstatix::shapiro_test(x) %>%
  rstatix::add_significance(symbols = c("\u25E4\u25E4\u25E4\u25E4", "\u25E4\u25E4\u25E4", "\u25E4\u25E4", "\u25E4", "")) %>% 
  dplyr::mutate(normal = p > 0.05)

if(any(normality$normal)){
  effect_size_normal <- people %>% 
    dplyr::mutate(x = get(metrics[i])) %>% 
    dplyr::filter(x > 0) %>%
    dplyr::bind_rows(baseline, .id = "case") %>%
    dplyr::mutate(case = as.numeric(case)) %>%
    dplyr::select(case, experiment_name, department, x) %>% 
    merge(normality %>% dplyr::select(experiment_name, department, normal)) %>% 
    dplyr::filter(normal) %>% 
    dplyr::group_by(experiment_name, department) %>%
    rstatix::cohens_d(x ~ case, ref.group = "2", paired = F, var.equal = F) %>%
    rstatix::add_significance() %>%
    dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
    dplyr::filter(experiment_name != "1. Baseline")
}else{
  effect_size_normal <- data.frame()
}

effect_size_nonnormal <- people %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, department, x) %>% 
  merge(normality %>% dplyr::select(experiment_name, department, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::group_by(experiment_name, department) %>%
  rstatix::wilcox_effsize(x ~ case, ref.group = "2", paired = F) %>%
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

effect_size <- rbind(effect_size_normal, effect_size_nonnormal)

if(any(normality$normal)){
  ttest <- people %>% 
    dplyr::mutate(x = get(metrics[i])) %>% 
    dplyr::filter(x > 0) %>%
    dplyr::bind_rows(baseline, .id = "case") %>%
    dplyr::mutate(case = as.numeric(case)) %>%
    dplyr::select(case, experiment_name, department, x) %>%
    merge(normality %>% dplyr::select(experiment_name, department, normal)) %>% 
    dplyr::filter(normal) %>% 
    dplyr::group_by(experiment_name, department) %>%
    rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>%
    rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
    dplyr::filter(experiment_name != "1. Baseline")
}else{
  ttest <- data.frame(matrix(ncol = 7, nrow=0))
  colnames(ttest) <- c("experiment_name", "department", "method", "estimate", "statistic", "p", "p.signif")
}

wilcoxtest <- people %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  merge(normality %>% dplyr::select(experiment_name, department, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::select(case, experiment_name, department, x) %>%
  dplyr::group_by(experiment_name, department) %>%
  rstatix::wilcox_test(x ~ case, ref.group = "2", paired = F, exact=F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

hypothesis_test <- rbind(
  ttest %>% dplyr::select(experiment_name, department, method, estimate, statistic, p, p.signif), 
  wilcoxtest %>% dplyr::select(experiment_name, department, method, estimate, statistic, p, p.signif))


significant <- merge(
  effect_size %>% dplyr::mutate(cond1 = magnitude %in% c("moderate", "large")),
  hypothesis_test %>% dplyr::mutate(cond2 = p < 1e-4),
  by=c("experiment_name", "department")
) %>% 
  dplyr::mutate(cond = cond1 & cond2) %>%
  dplyr::select(experiment_name, department, cond)

# density plot without colors
people %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(x > 0) %>%
  ggplot2::ggplot()+
  # BASELINE RIDGES
  ggridges::geom_density_ridges(
    data = baseline,
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.2, alpha=1.0, stat = "density", color="black", fill="gray90", linetype="dotted"
  )+
  # COLOR RIDGES
  ggridges::geom_density_ridges(
    data = . %>% dplyr::filter(experiment_id != 1),
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.5, alpha=0.1, stat = "density", show.legend = F, fill="gray90", color="black",
  )+
  # BASELINE CENTRAL MEASURE
  ggplot2::geom_segment(
    data = baseline %>% dplyr::group_by(experiment_name, department) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup(),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="gray50",
  )+
  # COLOR CENTRAL MEASURE
  ggplot2::geom_segment(
    data = . %>% dplyr::group_by(experiment_name, department) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="black",
  )+
  # SEGMENT DIFFERENCE
  ggplot2::geom_segment(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, department) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp1, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp2, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 color=diff_rel),
    size=2, lineend="butt", show.legend = T
  )+
  # TEXT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, department) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 > tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, color=diff_rel,
                 label=label), hjust=-0.1, size=2.5, fontface="bold"
  )+
  # SIGNIFICANT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, department) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 < tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      merge(significant, sort = F) %>% 
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, label=ifelse(cond, "\u2731", NA)), 
    color="#F06800", hjust=1.1, size=2.5, fontface="bold", na.rm=T
  )+
  # NORMALITY
  ggplot2::geom_text(
    data = normality,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.05, label=p.signif),
    color="black", fontface="bold", hjust=0, vjust=0.5, size=2.25, angle=90, check_overlap = F)+
  # HYPOTHESIS TEST DIFFERENCE
  ggplot2::geom_text(
    data = hypothesis_test,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.05, label=p.signif),
    color="gray50", fontface="bold", hjust=0, vjust=0.5, size=2.25, angle=90, check_overlap = F)+
  # EFFECT SIZE DIFFERENCE
  ggplot2::geom_text(
    data = effect_size,
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.5, label=p.signif),
    color="black", fontface="bold", hjust=0.4, vjust=0.0, size=2.25, angle=0)+
  # # ANNOTATE
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(department == "department1") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Shapiro-Wilk\nNormality Test", color="black", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(department == "department1") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.1, size=0.25, color="black", 
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(department == "department2") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Welch / Mann–\nWhitney test", color="gray50", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(department == "department2") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.3, size=0.25, color="gray50"
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(department == "department3") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Cohen / Wilcoxon\nEffect Size", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(department == "department3") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.5, size=0.25
  # )+
  ggplot2::facet_wrap(. ~ department, scales="fixed", nrow=1)+
  ggplot2::scale_x_continuous(breaks = breaks[[i]], limits=limits[[i]])+
  ggplot2::scale_color_gradient2(low="#00F260", mid = "#0575E6", high = "#fc4a1a", midpoint = 0,
                                 breaks = color_breaks[[i]], limits=color_limits[[i]])+
  ggplot2::labs(x=latex2exp::TeX(metrics_labels[i]), y="Density", color="Mean Difference %")+
  ggplot2::guides(color = ggplot2::guide_colourbar(title.position = "top", title.hjust = 0.5))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.position = c(-0.012, -0.04),
    legend.direction = "horizontal",
    legend.key.height = ggplot2::unit(6, 'pt'),
    legend.key.width = ggplot2::unit(14, 'pt'),
    legend.justification = "right",
    legend.title = ggplot2::element_text(size=8),
    legend.text = ggplot2::element_text(size=8),
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(angle=0),
  ) -> g

ggplot2::ggsave("people_density_ridges.pdf", width=9, height=7, device = cairo_pdf)


# BUILDING ----------------------------------------------------------------

building_places <- places %>% 
  dplyr::mutate(volume = area * height) %>% 
  dplyr::group_by(experiment_id, experiment_name, run) %>%
  dplyr::summarise(
    `Avg.~max~CO[2]~level~(ppm)` = weighted.mean(CO2_level_max, volume, na.rm=T),
    `Avg.~max~quanta~level~(ppm)` = weighted.mean(quanta_level_max, volume, na.rm=T),
  ) %>% 
  dplyr::ungroup() %>% 
  # tidyr::pivot_longer(cols = c(`Avg.~max~CO[2]~level~(ppm)`, `Avg.~max~quanta~level~(ppm)`), names_to = "var", values_to = "x")
  tidyr::pivot_longer(cols = c(`Avg.~max~CO[2]~level~(ppm)`), names_to = "var", values_to = "x")

building_people <- people %>% 
  dplyr::filter(quanta_inhaled_max > 0) %>% 
  dplyr::group_by(experiment_id, experiment_name, run) %>%
  dplyr::summarise(
    `Avg.~CO[2]~level~inhaled~(ppm)` = mean(CO2_level_mean, na.rm=T),
    `Avg.~quanta~inhaled~(quanta)` = mean(quanta_inhaled_max, na.rm=T)
  ) %>% 
  # tidyr::pivot_longer(cols = c(`Avg.~CO[2]~level~inhaled~(ppm)`, `Avg.~quanta~inhaled~(quanta)`), names_to = "var", values_to = "x")
  tidyr::pivot_longer(cols = c(`Avg.~quanta~inhaled~(quanta)`), names_to = "var", values_to = "x")

building <- dplyr::bind_rows(building_places, building_people)

baseline <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::filter(experiment_id == 1) %>%
  dplyr::select(-experiment_id, -experiment_name) %>%
  dplyr::bind_cols(experiment_df %>%
                     tidyr::pivot_wider(names_from = "experiment_id", values_from = "experiment_name")) %>%
  tidyr::pivot_longer(cols = experiment_df$experiment_id %>% as.character(),
                      names_to = "experiment_id", values_to = "experiment_name") %>% 
  dplyr::mutate(experiment_id = as.numeric(experiment_id))

normality <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::group_by(experiment_name, var) %>%
  dplyr::sample_n(min(dplyr::n(), 5000)) %>% 
  rstatix::shapiro_test(x) %>%
  rstatix::add_significance(symbols = c("\u25E4\u25E4\u25E4\u25E4", "\u25E4\u25E4\u25E4", "\u25E4\u25E4", "\u25E4", "")) %>% 
  dplyr::mutate(normal = p > 0.05)

effect_size_normal <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, var, x) %>% 
  merge(normality %>% dplyr::select(experiment_name, var, normal)) %>%
  dplyr::filter(normal) %>%
  dplyr::group_by(experiment_name, var) %>% 
  rstatix::cohens_d(x ~ case, ref.group = "2", paired = F, var.equal = F) %>% 
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

effect_size_nonnormal <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, var, x) %>% 
  merge(normality %>% dplyr::select(experiment_name, var, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::group_by(experiment_name, var) %>%
  rstatix::wilcox_effsize(x ~ case, ref.group = "2", paired = F) %>%
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

effect_size <- rbind(effect_size_normal, effect_size_nonnormal)

ttest <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  dplyr::select(case, experiment_name, var, x) %>%
  merge(normality %>% dplyr::select(experiment_name, var, normal)) %>% 
  dplyr::filter(normal) %>% 
  dplyr::group_by(experiment_name, var) %>%
  rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

wilcoxtest <- building %>% 
  # dplyr::filter(x > 0) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>%
  merge(normality %>% dplyr::select(experiment_name, var, normal)) %>% 
  dplyr::filter(!normal) %>% 
  dplyr::select(case, experiment_name, var, x) %>%
  dplyr::group_by(experiment_name, var) %>%
  rstatix::wilcox_test(x ~ case, ref.group = "2", paired = F, exact=F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", "")) %>%
  dplyr::filter(experiment_name != "1. Baseline")

hypothesis_test <- rbind(
  ttest %>% dplyr::select(experiment_name, var, method, estimate, statistic, p, p.signif), 
  wilcoxtest %>% dplyr::select(experiment_name, var, method, estimate, statistic, p, p.signif))


significant <- merge(
  effect_size %>% dplyr::mutate(cond1 = magnitude %in% c("moderate", "large")),
  hypothesis_test %>% dplyr::mutate(cond2 = p < 1e-4),
  by=c("experiment_name", "var")
) %>% 
  dplyr::mutate(cond = cond1 & cond2) %>%
  dplyr::select(experiment_name, var, cond)

# density plot without colors
building %>% 
  # dplyr::filter(x > 0) %>%
  ggplot2::ggplot()+
  # BASELINE RIDGES
  ggridges::geom_density_ridges(
    data = baseline,
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.2, alpha=1.0, stat = "density", color="black", fill="gray90", linetype="dotted"
  )+
  # COLOR RIDGES
  ggridges::geom_density_ridges(
    data = . %>% dplyr::filter(experiment_id != 1),
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), height = ..scaled..), 
    scale=0.6, size=0.5, alpha=0.1, stat = "density", show.legend = F, fill="gray90", color="black",
  )+
  # BASELINE CENTRAL MEASURE
  ggplot2::geom_segment(
    data = baseline %>% dplyr::group_by(experiment_name, var) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup(),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="gray50",
  )+
  # COLOR CENTRAL MEASURE
  ggplot2::geom_segment(
    data = . %>% dplyr::group_by(experiment_name, var) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name)))),
    size=0.1, color="black",
  )+
  # SEGMENT DIFFERENCE
  ggplot2::geom_segment(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, var) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp1, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 xend=tmp2, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15,
                 color=diff_rel),
    size=2, lineend="butt", show.legend = T
  )+
  # TEXT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, var) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 > tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, color=diff_rel,
                 label=label), hjust=-0.1, size=2.5, fontface="bold"
  )+
  # SIGNIFICANT DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, var) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]), # experiments
        tmp2 = mean(x[case==2]), # baseline
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 < tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      merge(significant, sort = F) %>% 
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=pos, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, label=ifelse(cond, "\u2731", NA)), 
    color="#F06800", hjust=1.1, size=2.5, fontface="bold", na.rm=T
  )+
  # NORMALITY
  ggplot2::geom_text(
    data = normality %>% dplyr::mutate(
      xloc = dplyr::recode(var, `Avg.~max~CO[2]~level~(ppm)`=950, `Avg.~CO[2]~level~inhaled~(ppm)`=750,
                           `Avg.~quanta~inhaled~(quanta)`=0.15, `Avg.~max~quanta~level~(ppm)`=0.05)),
    ggplot2::aes(x=xloc, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.05, label=p.signif),
    color="black", fontface="bold", hjust=0, vjust=0.5, size=3.25, angle=90, check_overlap = F)+
  # HYPOTHESIS TEST DIFFERENCE
  ggplot2::geom_text(
    data = hypothesis_test %>% dplyr::mutate(
      xloc = dplyr::recode(var, `Avg.~max~CO[2]~level~(ppm)`=950, `Avg.~CO[2]~level~inhaled~(ppm)`=750,
                           `Avg.~quanta~inhaled~(quanta)`=0.15, `Avg.~max~quanta~level~(ppm)`=0.05)),
    ggplot2::aes(x=xloc, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.05, label=p.signif),
    color="gray50", fontface="bold", hjust=0, vjust=0.5, size=3.25, angle=90, check_overlap = F)+
  # EFFECT SIZE DIFFERENCE
  ggplot2::geom_text(
    data = effect_size %>% dplyr::mutate(
      xloc = dplyr::recode(var, `Avg.~max~CO[2]~level~(ppm)`=950, `Avg.~CO[2]~level~inhaled~(ppm)`=750,
                           `Avg.~quanta~inhaled~(quanta)`=0.15, `Avg.~max~quanta~level~(ppm)`=0.05)),
    ggplot2::aes(x=xloc, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.6, label=p.signif),
    color="black", fontface="bold", hjust=0.4, vjust=0.0, size=3, angle=0)+
  # # ANNOTATE
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(var == "Avg.~max~CO[2]~level~(ppm)") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Shapiro-Wilk\nNormality Test", color="black", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(var == "Avg.~max~CO[2]~level~(ppm)") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.1, size=0.25, color="black", 
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(var == "Avg.~CO[2]~level~inhaled~(ppm)") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Welch / Mann–\nWhitney test", color="gray50", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(var == "Avg.~CO[2]~level~inhaled~(ppm)") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.3, size=0.25, color="gray50"
  # )+
  # ggplot2::geom_text(
  #   data = . %>% dplyr::filter(var == "Avg.~quanta~inhaled~(quanta)") %>% dplyr::sample_n(1), check_overlap = T,
  #   x=textloc[i], y=7.3, label="Cohen / Wilcoxon\nEffect Size", size=2, hjust=1, vjust=0.5)+
  # ggplot2::geom_segment(
  #   data = . %>% dplyr::filter(var == "Avg.~quanta~inhaled~(quanta)") %>% dplyr::sample_n(1),
  #   x=textloc[i], y=7.3, xend=xloc[i], yend=7.5, size=0.25
  # )+
  ggplot2::facet_wrap(. ~ var, scales="free_x", nrow=1, labeller = ggplot2::label_parsed)+
  ggplot2::scale_x_continuous(breaks = scales::breaks_extended(4))+
  # ggplot2::scale_x_continuous(breaks = breaks[[i]], limits=limits[[i]])+
  ggplot2::scale_color_gradient2(low="#00F260", mid = "#0575E6", high = "#fc4a1a", midpoint = 0,
                                 breaks = c(-100,-50,0,50,100), limits=c(-100,100))+
  ggplot2::labs(x="Value", y="Density", color="Mean Difference %")+
  ggplot2::guides(color = ggplot2::guide_colourbar(title.position = "top", title.hjust = 0.5))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.position = c(-0.012, -0.02),
    legend.direction = "horizontal",
    legend.key.height = ggplot2::unit(6, 'pt'),
    legend.key.width = ggplot2::unit(14, 'pt'),
    legend.justification = "right",
    legend.title = ggplot2::element_text(size=8),
    legend.text = ggplot2::element_text(size=8),
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.x = ggplot2::element_text(angle=0, size=8, family="Roboto", color="gray10"),
  ) -> g

ggplot2::ggsave("building_density_ridges.pdf", width=6, height=8, device = cairo_pdf)


# COEFFICIENT VARIATION ---------------------------------------------------

nsamples <- 10
nmax <- 1000
places %>% 
  dplyr::filter(experiment_id == 1, place == 2) %>% 
  dplyr::mutate(x = CO2_level_max) %>% 
  dplyr::mutate(x = quanta_level_max) %>% 
  dplyr::slice(rep(dplyr::row_number(), nsamples)) %>%
  dplyr::mutate(sample = floor((dplyr::row_number()-1) / nmax) ) %>% 
  dplyr::group_by(sample) %>% 
  dplyr::sample_frac(1) %>%
  dplyr::mutate(
    n = seq_along(x),
    m = cumsum(x) / n,
    m2 = cumsum(x * x) / n,
    v = (m2 - m * m) * (n / (n - 1)),
    s = sqrt(v),
    cv = s / m,
    cv2 = cv * (1 + 1/(4*n))
  ) %>% 
  dplyr::ungroup() %>% 
  # tidyr::pivot_longer(cols = c(x, m, s, cv), names_to = "key", values_to = "value") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=n, y=cv, group=sample), alpha=0.1, na.rm=T)+
  ggplot2::lims(y=c(0, NA))
# ggplot2::scale_color_viridis_c()
# ggplot2::geom_line(ggplot2::aes(x=n, y=value, group=sample), alpha=0.05, na.rm = T)+
# ggplot2::facet_grid(rows=dplyr::vars(key), scales="free_y")


# places
nsamples <- 30
nmax <- 1000
places %>%
  dplyr::mutate(x = CO2_level_max) %>%
  # dplyr::mutate(x = quanta_level_max) %>%
  # dplyr::filter(x > 0) %>% 
  dplyr::group_by(experiment_name, name_ext) %>% 
  dplyr::slice(rep(dplyr::row_number(), nsamples)) %>% 
  dplyr::mutate(sample = floor((dplyr::row_number()-1) / nmax) + dplyr::cur_group_id() ) %>% 
  dplyr::ungroup() %>% 
  dplyr::group_by(experiment_name, name_ext, sample) %>% 
  dplyr::sample_frac(1) %>%
  dplyr::mutate(
    n = seq_along(x),
    m = cumsum(x) / n,
    m2 = cumsum(x * x) / n,
    v = (m2 - m * m) * (n / (n - 1)),
    s = sqrt(v),
    cv = s / m,
    cv2 = cv * (1 + 1/(4*n))
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(n %in% c(1,seq(0, 1000, 50))) %>% 
  # tidyr::pivot_longer(cols = c(x, m, s, cv), names_to = "key", values_to = "value") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=n, y=s, group=sample), alpha=0.1, na.rm=T, size=0.3)+
  ggplot2::facet_grid(rows = dplyr::vars(name_ext), cols=dplyr::vars(experiment_name), scales = "free_y")+
  ggplot2::geom_vline(ggplot2::aes(xintercept=500), linetype="dashed", color="blue", size=0.3)+
  ggplot2::scale_x_continuous(breaks=c(0,300,600,900))+
  ggplot2::scale_y_continuous(n.breaks = 4, limits=c(0, NA))+
  # ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, CO_2 \\, level \\, (ppm)$"))+
  ggplot2::labs(x=latex2exp::TeX("$Number\\,of\\,simulations\\; S_{run}$"), y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, Quanta \\, level \\, (ppm)$"))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    strip.text.x = ggplot2::element_text(angle=0, hjust=0.5, vjust=0, size=7),
    strip.text.y = ggplot2::element_text(angle=0, hjust=0, vjust=0.5, size=7),
    strip.background = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size=6),
    axis.title = ggplot2::element_text(size=8)
  ) -> g

ggplot2::ggsave("cv_places.pdf", width=9, height=11, device = cairo_pdf)

# people
nsamples <- 50
nmax <- 1000
people %>%
  dplyr::mutate(x = CO2_level_mean) %>%
  # dplyr::mutate(x = quanta_inhaled_max) %>%
  dplyr::group_by(experiment_name, department, run) %>% 
  dplyr::summarise(x = mean(x), .groups = "keep") %>% 
  dplyr::ungroup() %>%
  dplyr::group_by(experiment_name, department) %>% 
  dplyr::slice(rep(dplyr::row_number(), nsamples)) %>% 
  dplyr::mutate(sample = floor((dplyr::row_number()-1) / nmax) + dplyr::cur_group_id() ) %>% 
  dplyr::ungroup() %>% 
  dplyr::group_by(experiment_name, department, sample) %>% 
  dplyr::sample_frac(1) %>%
  dplyr::mutate(
    n = seq_along(x),
    m = cumsum(x) / n,
    m2 = cumsum(x * x) / n,
    v = (m2 - m * m) * (n / (n - 1)),
    s = sqrt(v),
    cv = s / m,
    cv2 = cv * (1 + 1/(4*n))
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(n %in% c(1,seq(0, 1000, 50))) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_line(ggplot2::aes(x=n, y=s, group=sample), alpha=0.1, na.rm=T, size=0.3)+
  ggplot2::facet_grid(rows = dplyr::vars(department), cols=dplyr::vars(experiment_name), scales = "free_y")+
  ggplot2::geom_vline(ggplot2::aes(xintercept=500), linetype="dashed", color="blue", size=0.3)+
  ggplot2::scale_x_continuous(breaks=c(0,300,600,900))+
  ggplot2::scale_y_continuous(n.breaks = 4, limits=c(0, NA))+
  # ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;mean \\, CO_2 \\, inhaled \\, (ppm)$"))+
  ggplot2::labs(x=latex2exp::TeX("$Number\\,of\\,simulations\\; S_{run}$"), y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, Quanta \\, inhaled \\, (quanta)$"))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    strip.text.x = ggplot2::element_text(angle=0, hjust=0.5, vjust=0, size=7),
    strip.text.y = ggplot2::element_text(angle=0, hjust=0, vjust=0.5, size=7),
    strip.background = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size=6),
    axis.title = ggplot2::element_text(size=8)
  ) -> g

ggplot2::ggsave("cv_people.pdf", width=9, height=7, device = cairo_pdf)




# LEGEND ----------------------------------------------------------------

case1 <- places %>% 
  dplyr::filter(experiment_id == 2) %>% 
  dplyr::group_by(run) %>% 
  dplyr::summarise(x = mean(CO2_level_max, na.rm=T)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(case = 1)

case2 <- places %>% 
  dplyr::filter(experiment_id == 1) %>% 
  dplyr::group_by(run) %>% 
  dplyr::summarise(x = mean(CO2_level_max, na.rm=T)) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(case = 2)

df <- dplyr::bind_rows(case1, case2)

normality <- df %>% 
  dplyr::sample_n(min(dplyr::n(), 5000)) %>% 
  rstatix::shapiro_test(x) %>%
  rstatix::add_significance(symbols = c("\u25E4\u25E4\u25E4\u25E4", "\u25E4\u25E4\u25E4", "\u25E4\u25E4", "\u25E4", "")) %>% 
  dplyr::mutate(normal = p > 0.05)

effect_size <- df %>% 
  rstatix::cohens_d(x ~ case, ref.group = "2", paired = F, var.equal = F) %>% 
  rstatix::add_significance() %>%
  dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="-", small="S", moderate="M", large="L"))

hypothesis_test <- df %>% 
  rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>%
  rstatix::add_significance(symbols = c("\u25E2\u25E2\u25E2\u25E2", "\u25E2\u25E2\u25E2", "\u25E2\u25E2", "\u25E2", ""))

# density plot without colors
df %>% 
  ggplot2::ggplot()+
  # BASELINE RIDGES
  ggplot2::geom_density(
    data = case2,
    ggplot2::aes(x=x, y = ..scaled..), 
    size=0.2, alpha=1.0, color="black", fill="gray90", linetype="dotted"
  )+
  # COLOR RIDGES
  ggplot2::geom_density(
    data = case1,
    ggplot2::aes(x=x, y = ..scaled..), 
    size=0.5, alpha=0.1, stat = "density", show.legend = F, fill="gray90", color="black",
  )+
  # BASELINE CENTRAL MEASURE
  ggplot2::geom_segment(
    data = case2 %>% dplyr::summarise(tmp = mean(x), .groups = "keep"),
    ggplot2::aes(x=tmp, y=-0.15, xend=tmp, yend=0), size=0.1, color="gray50",
  )+
  # COLOR CENTRAL MEASURE
  ggplot2::geom_segment(
    data = case1 %>% dplyr::summarise(tmp = mean(x), .groups = "keep"),
    ggplot2::aes(x=tmp, y=-0.15, xend=tmp, yend=0), size=0.1, color="black",
  )+
  # SEGMENT DIFFERENCE
  ggplot2::geom_segment(
    data = dplyr::bind_rows(case1, case2) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        .groups = "keep") %>%
      dplyr::ungroup(),
    ggplot2::aes(x=tmp1, y=-0.15, xend=tmp2, yend=-0.15, color=diff_rel),
    size=2, lineend="butt", show.legend = F
  )+
  # TEXT DIFFERENCE
  ggplot2::geom_text(
    data = dplyr::bind_rows(case1, case2) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 > tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup(),
    ggplot2::aes(x=pos, y=-0.15, color=diff_rel, label=label), hjust=-0.1, size=5, fontface="bold", show.legend = F
  )+
  # SIGNIFICANT DIFFERENCE
  ggplot2::geom_text(
    data = dplyr::bind_rows(case1, case2) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        diff_abs = (tmp1-tmp2),
        diff_rel = diff_abs / tmp2 * 100,
        label = round(diff_rel, digits = 0),
        label = paste0(ifelse(label > 0, "+", ifelse(label < 0, "-", "")), abs(label), "%"),
        pos = ifelse(tmp2 < tmp1, tmp2, tmp1),
        .groups = "keep") %>%
      dplyr::ungroup(),
    ggplot2::aes(x=pos, y=-0.15, label="\u2731"), 
    color="#F06800", hjust=1.1, size=5, fontface="bold", na.rm=T
  )+
  # NORMALITY
  ggplot2::geom_text(
    data = normality,
    ggplot2::aes(x=1045, y=0.4, label=p.signif),
    color="black", fontface="bold", hjust=0, vjust=0.5, size=7, angle=90, check_overlap = F)+
  # HYPOTHESIS TEST DIFFERENCE
  ggplot2::geom_text(
    data = hypothesis_test,
    ggplot2::aes(x=1045, y=0.4, label=p.signif),
    color="gray50", fontface="bold", hjust=0, vjust=0.5, size=7, angle=90, check_overlap = F)+
  # EFFECT SIZE DIFFERENCE
  ggplot2::geom_text(
    data = effect_size,
    ggplot2::aes(x=1046, y=0.65, label=p.signif),
    color="black", fontface="bold", hjust=0.5, vjust=0.0, size=6, angle=0)+
  # ANNOTATE
  # significant difference
  ggplot2::annotate("text", x=830, y=-0.1, label="Significant\ndifference", hjust=1, vjust=0.5, color="#F06800", fontface="bold")+
  ggplot2::annotate("point", x=833, y=-0.1, color="#F06800", size=1)+
  ggplot2::annotate("segment", x=833, y=-0.1, xend=847, yend=-0.14, size=0.3, color="#F06800")+
  # difference in means
  ggplot2::annotate("text", x=983, y=-0.1, label="Difference between means\n(in percentage)", hjust=0, vjust=0.5, color="#2e81db", fontface="bold")+
  ggplot2::annotate("point", x=978, y=-0.1, color="#2e81db", size=1)+
  ggplot2::annotate("segment", x=978, y=-0.1, xend=962, yend=-0.14, size=0.3, color="#2e81db")+
  # baseline / modified
  ggplot2::annotate("text", x=945, y=0.25, label="Baseline\ndistribution", hjust=0.5, vjust=0.5, color="gray50", fontface="bold")+
  ggplot2::annotate("text", x=855, y=0.25, label="Experiment\ndistribution", hjust=0.5, vjust=0.5, color="black", fontface="bold")+
  # normality
  ggplot2::annotate("text", x=1025, y=0.32, label="Shapiro-Wilk\nnormality test\np-value", hjust=1, vjust=0.5, lineheight=0.8, fontface="bold")+
  ggplot2::annotate("text", x=995, y=0.13, label="\u25E3 <0.0001\n\u25E3 <0.001\n\u25E3 <0.01\n\u25E3 <0.05",
                    angle=0, hjust=0, vjust=0.5, lineheight = 0.85, color="black")+
  ggplot2::annotate("point", x=1005, y=0.4, size=1)+
  ggplot2::annotate("curve", x=1005, y=0.4, xend=1035, yend=0.52, size=0.2, curvature = -0.2, angle = 90)+
  # ttest
  ggplot2::annotate("text", x=1065, y=0.32, label="Welch's or\nMann–Whitney\ntest p-value", hjust=0, vjust=0.5, lineheight=0.8, fontface="bold", color="gray50")+
  ggplot2::annotate("text", x=1065, y=0.13, label="\u25E5 <0.0001\n\u25E5 <0.001\n\u25E5 <0.01\n\u25E5 <0.05",
                    angle=0, hjust=0, vjust=0.5, lineheight = 0.85, color="gray50")+
  ggplot2::annotate("point", x=1080, y=0.4, size=1, color="gray50")+
  ggplot2::annotate("curve", x=1080, y=0.4, xend=1055, yend=0.57, size=0.2, curvature = 0.2, angle = 90, color="gray50")+
  # effect size
  ggplot2::annotate("text", x=1015, y=0.90, label="Wilcoxon or\nCohen’s\neffect size", hjust=1, vjust=0.5, lineheight=0.8, fontface="bold")+
  ggplot2::annotate("text", x=1030, y=0.90, label="negligible (-) < 0.2\n0.2 < small (S) < 0.5\n0.5 < moderate (M) < 0.8\nlarge (L) > 0.8",
                    hjust=0, vjust=0.5, lineheight=0.85)+
  ggplot2::annotate("segment", x=1023, y=0.82, xend=1023, yend=0.97, size=0.2)+
  ggplot2::annotate("point", x=1000, y=0.8, size=1)+
  ggplot2::annotate("curve", x=1000, y=0.8, xend=1038, yend=0.67, size=0.2, curvature = 0.2, angle = 45)+
  # SCALES
  ggplot2::scale_x_continuous(breaks = scales::breaks_extended(6), limits=c(800, 1100))+
  ggplot2::scale_color_gradient2(low="#00F260", mid = "#0575E6", high = "#fc4a1a", midpoint = 0,
                                 breaks = c(-100,-50,0,50,100), limits=c(-100,100))+
  ggplot2::labs(x=latex2exp::TeX("$Metric\\,(CO_2\\,or\\,quanta)$"), y="Density", color="Mean Difference %")+
  ggplot2::guides(color = ggplot2::guide_colourbar(title.position = "top", title.hjust = 0.5))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    legend.position = c(-0.012, -0.02),
    legend.direction = "horizontal",
    legend.key.height = ggplot2::unit(6, 'pt'),
    legend.key.width = ggplot2::unit(14, 'pt'),
    legend.justification = "right",
    legend.title = ggplot2::element_text(size=8),
    legend.text = ggplot2::element_text(size=8),
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.x = ggplot2::element_text(angle=0, size=8),
  )

ggplot2::ggsave("legend_density.pdf", width=8, height=5, device = cairo_pdf)


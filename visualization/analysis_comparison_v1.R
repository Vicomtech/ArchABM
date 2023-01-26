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
  "4. Better passive\nventilation",
  "5. Better active\nventilation",
  "6. Working\nin shifts",
  "7. Limit events\nduration",
  "8. Wearing masks"
)
experiment_df <- data.frame(experiment_name, stringsAsFactors = F) %>% tibble::rowid_to_column(var = "experiment_id")

# COLOR PALETTE
values <- results[[1]]$places_info$activity %>% unique %>% sort
palette_activity <- c("#BF506E", "#34B1BF", "#89BF7A", "#571FA6", "#9cadbc", "#F2B950")
names(palette_activity) <- values

palette_experiments <- ggsci::pal_d3()(8) %>% rev  # D3, IGV, NEJM
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
  dplyr::filter(name != "home")


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
  "$max \\, Quanta \\, (ppm)$", 
  "$max \\, \\Delta Quanta \\, (ppm)$"
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

digits <- c(0,0,2,2)
i <- 1
# for(i in 1:length(metrics)){
# }
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


draw_key_polygon3 <- function(data, params, size) {
  lwd <- min(data$size, min(size) / 10)
  
  grid::rectGrob(
    width = grid::unit(0.6, "npc"),
    height = grid::unit(0.6, "npc"),
    gp = grid::gpar(
      col = data$colour,
      fill = ggplot2::alpha(data$fill, data$alpha),
      lty = data$linetype,
      lwd = lwd * ggplot2::.pt,
      linejoin = "mitre"
    ))
}

# palette_experiments2 <- palette_experiments
# names(palette_experiments2) <- stringr::str_replace(names(palette_experiments2), "\n", ": ")
places %>% 
  # dplyr::filter(experiment_id %in% c(1,3)) %>%
  dplyr::mutate(experiment_name = stringr::str_replace(experiment_name, "\n", ": ")) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_density(ggplot2::aes(x=get(metrics[i]), fill=experiment_name, color=experiment_name), 
                        size=.2, alpha=.1, key_glyph = draw_key_polygon3)+
  # ggplot2::geom_histogram(ggplot2::aes(x=get(metrics[i]), fill=experiment_name), size=.2, alpha=.5, bins=40)+
  # ggplot2::geom_freqpoly(ggplot2::aes(x=get(metrics[i]), color=experiment_name), size=0.5, alpha=0.8, bins=40)+
  ggplot2::facet_wrap(.~name_ext, scales = "free", nrow=4, strip.position = "top",)+
  ggplot2::scale_fill_manual(values=palette_experiments)+
  ggplot2::scale_color_manual(values=palette_experiments, guide="none")+
  # ggplot2::scale_y_continuous(labels = scales::label_scientific)+
  ggplot2::scale_y_continuous(label= function(x) {
    ifelse(x==0, "0", parse(text=gsub("[+]", "", gsub("e", "%*%10^", scales::scientific_format()(x)))))} ) +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(alpha=1), ncol = 1),
    # color = ggplot2::guide_legend(override.aes = list(alpha=1)),
    )+
  ggplot2::labs(x=latex2exp::TeX(metrics_labels[i]), y="Density", fill="Experiment")+
  ggplot2::theme_bw()+
  # ggpubr::theme_cleveland()+
  ggplot2::theme(
    # legend.position = "top"
    # legend.position = c(.91,.15), # ncol=5
    legend.position = c(.59,.09), # nrow=5
    axis.text = ggplot2::element_text(size=8),
    axis.title.x = ggplot2::element_text(hjust=0.2),
    axis.title.y = ggplot2::element_text(hjust=0.5),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    # panel.spacing = ggplot2::unit(1, "lines"),
    # plot.margin = grid::unit(1, "lines"),
    # strip.placement = "outside",
    strip.background = ggplot2::element_blank(),
  )

ggplot2::ggsave("places_density.pdf", width=10, height=10, device = cairo_pdf)

xloc <- c(2000, 0, 0.4, 0)
textloc <- c(1700, 0, 0.35, 0)
color_breaks <- list(
  c(-40,-20,0,20,40),
  c(-40,-20,0,20,40),
  c(-80,-40,0,40,80),
  c(-80,-40,0,40,80)
)
color_limits <- list(
  c(-55,55),
  c(-55,55),
  c(-80,80),
  c(-80,80)
)

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
        .groups = "keep") %>%
      dplyr::ungroup() %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=tmp2, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, color=diff_rel,
                 label=label), hjust=-0.1, size=2.5, fontface="bold"
  )+
  # TEST SEPARATORS
  ggplot2::geom_text(
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.00, label="|"),
    color="black", hjust=0.5, vjust=1.0, size=1, angle=90)+
  ggplot2::geom_text(
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.22, label="|"),
    color="black", hjust=0.5, vjust=1.0, size=1, angle=90)+
  ggplot2::geom_text(
    data = . %>% dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.38, label="|"),
    color="black", hjust=0.5, vjust=1.0, size=1, angle=90)+
  ggplot2::geom_text(
    data = . %>% dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.60, label="|"),
    color="black", hjust=0.5, vjust=1.0, size=1, angle=90)+
  # NORMALITY
  ggplot2::geom_text(
    data = . %>% dplyr::group_by(experiment_name, name_ext) %>%
      rstatix::shapiro_test(x) %>% rstatix::add_significance() %>%
      dplyr::mutate(p.signif = stringr::str_replace(p.signif, "ns", "¯")),
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.11, label=p.signif),
    color="black", fontface="bold", hjust=0.5, vjust=1.0, size=2, angle=90)+
  # EFFECT SIZE DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::select(case, experiment_name, name_ext, x) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      rstatix::cohens_d(x ~ case, ref.group = "2", paired = F, var.equal = F) %>%
      rstatix::add_significance() %>%
      dplyr::mutate(p.signif = dplyr::recode(magnitude, negligible="¯", small="*", moderate="**", large="***")) %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.3, label=p.signif),
      color="black", fontface="bold", hjust=0.5, vjust=1.0, size=2, angle=90)+
  # HYPOTHESIS TEST DIFFERENCE
  ggplot2::geom_text(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::select(case, experiment_name, name_ext, x) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>%
      # rstatix::wilcox_test(x ~ case, ref.group = "2", paired = F, detailed = T) %>%
      rstatix::add_significance() %>%
      dplyr::mutate(p.signif = stringr::str_replace(p.signif, "ns", "¯")) %>%
      dplyr::filter(experiment_name != "1. Baseline"),
    ggplot2::aes(x=xloc[i], y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) + 0.49, label=p.signif),
    color="black", fontface="bold", hjust=0.5, vjust=1.0, size=2, angle=90)+
  # ANNOTATE
  ggplot2::geom_text(
    data = . %>% dplyr::filter(name_ext == "chief_office_A") %>% dplyr::sample_n(1), check_overlap = T,
    x=textloc[i], y=7.3, label="Shapiro-Wilk\nNormality Test", size=2, hjust=1, vjust=0.5)+
  ggplot2::geom_segment(
    data = . %>% dplyr::filter(name_ext == "chief_office_A") %>% dplyr::sample_n(1),
    x=textloc[i], y=7.3, xend=xloc[i], yend=7.1, size=0.25
  )+
  ggplot2::geom_text(
    data = . %>% dplyr::filter(name_ext == "chief_office_B") %>% dplyr::sample_n(1), check_overlap = T,
    x=textloc[i], y=7.3, label="Cohen's\nEffect Size", size=2, hjust=1, vjust=0.5)+
  ggplot2::geom_segment(
    data = . %>% dplyr::filter(name_ext == "chief_office_B") %>% dplyr::sample_n(1),
    x=textloc[i], y=7.3, xend=xloc[i], yend=7.3, size=0.25
  )+
  ggplot2::geom_text(
    data = . %>% dplyr::filter(name_ext == "chief_office_C") %>% dplyr::sample_n(1), check_overlap = T,
    x=textloc[i], y=7.3, label="Welch’s\nt-test", size=2, hjust=1, vjust=0.5)+
  ggplot2::geom_segment(
    data = . %>% dplyr::filter(name_ext == "chief_office_C") %>% dplyr::sample_n(1),
    x=textloc[i], y=7.3, xend=xloc[i], yend=7.5, size=0.25
  )+
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


# binline plot
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  # dplyr::filter(x > 0) %>%
  ggplot2::ggplot()+
  # BASELINE RIDGES
  ggridges::geom_density_ridges(
    data = baseline,
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name)),
    scale=0.5, size=0.2, alpha=0.4, stat = "binline", bins=40, color="gray10", fill="gray90", 
  )+
  # COLOR RIDGES
  ggridges::geom_density_ridges(
    data = . %>% dplyr::filter(experiment_id != 1),
    ggplot2::aes(x=x, y=forcats::fct_rev(experiment_name), 
                 fill=experiment_name, color=experiment_name),
    scale=0.5, size=0.5, alpha=0.1, stat = "binline", bins=40, show.legend = F,
  )+
  # SEGMENT CENTRAL MEASURE
  ggplot2::geom_segment(
    data = . %>%
      dplyr::bind_rows(baseline, .id = "case") %>%
      dplyr::mutate(case = as.numeric(case)) %>%
      dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(
        tmp1 = mean(x[case==1]),
        tmp2 = mean(x[case==2]),
        .groups = "keep") %>%
      dplyr::ungroup(),
    ggplot2::aes(x=tmp1, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, 
                 xend=tmp2, yend=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, 
                 color=experiment_name),
    size=2, lineend="butt", show.legend = F
  )+
  # BASELINE CENTRAL MEASURE
  ggplot2::geom_point(
    data = baseline %>% dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup(),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15),
    shape='|', size=1, stroke=3
  )+
  # COLOR CENTRAL MEASURE
  ggplot2::geom_point(
    data = . %>% dplyr::group_by(experiment_name, name_ext) %>%
      dplyr::summarise(tmp = mean(x), .groups = "keep") %>% dplyr::ungroup(),
    ggplot2::aes(x=tmp, y=as.numeric(as.factor(forcats::fct_rev(experiment_name))) - 0.15, color=experiment_name),
    shape='|', size=1, stroke=3, show.legend = F
  )+
  # ggplot2::facet_grid(cols=dplyr::vars(name_ext), scales="fixed")+
  ggforce::facet_wrap_paginate(. ~ name_ext, scales="fixed", ncol = 7, page = 1)+
  ggplot2::scale_color_manual(values=palette_experiments)+
  ggplot2::scale_fill_manual(values=palette_experiments)+
  ggplot2::scale_x_continuous(breaks = breaks[[i]])+
  ggplot2::labs(x=latex2exp::TeX(metrics_labels[i]), y="Density", fill="Experiment")+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = "top",
    legend.justification = "left",
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside"
  )

ggplot2::ggsave("temp.pdf", width=12, height=12, device = cairo_pdf)


# boxplot
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_boxplot(ggplot2::aes(x=experiment_name, y=x), outlier.color = NA, width=0.3)+
  ggplot2::geom_violin(ggplot2::aes(x=experiment_name, y=x), 
                       width=0.6, scale = "width", fill=NA,
                       draw_quantiles=c(0.25, 0.5, 0.75),
                       )+
  ggplot2::facet_wrap(name_ext ~ ., ncol=2, scales="free_y", strip.position = "right")+
  # ggplot2::scale_color_manual(values=palette_experiments)+
  ggplot2::labs(x="Experiment", y=latex2exp::TeX(metrics_labels[i]), fill="Experiment")+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = "top",
    legend.justification = "left",
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(angle=0),
    axis.text.x = ggplot2::element_text(angle=45, hjust=1, vjust=1)
  )

# flipped density
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges(
    ggplot2::aes(y=experiment_name, x=x), 
    scale=0.5, alpha=0.2, show.legend = F)+
  ggplot2::facet_grid(rows=dplyr::vars(name_ext), scales="fixed")+
  # ggplot2::scale_fill_manual(values=palette_experiments)+
  # ggplot2::scale_color_manual(values=palette_experiments)+
  ggplot2::coord_flip()+
  ggplot2::labs(y="Experiment", x=latex2exp::TeX(metrics_labels[i]), fill="Experiment")+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = "top",
    legend.justification = "left",
    strip.background = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(angle=0)
  )

# normality
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>%
  dplyr::group_by(experiment_name, name_ext) %>% 
  rstatix::shapiro_test(x) %>% 
  rstatix::add_significance()

places %>% 
  dplyr::mutate(x = get(metrics[i])) %>%
  ggpubr::ggqqplot(x = "x", facet.by = c("experiment_name", "name_ext"), size = 0.5, conf.int = T)

# pvalue, effect size, % diference in percentage

# ggstatsplot
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>% 
  # dplyr::filter(experiment_id == 2) %>% 
  dplyr::filter(name_ext == "lunch") %>%
  dplyr::select(case, experiment_name, name_ext, x) %>% 
  ggstatsplot::ggbetweenstats(
    x = experiment_name, 
    y = x,
    plot.type = "boxviolin",
    type = "parametric",
    pairwise.comparisons = T,
    pairwise.display = "significant",
    p.adjust.method = "holm",
    effsize.type = "unbiased",
    bf.prior = 0.707,
    bf.message = T,
    results.subtitle = T,
    xlab = NULL,
    ylab = NULL,
    caption = NULL,
    title = NULL,
    subtitle = NULL,
    var.equal = F,
    conf.level = 0.99,
    point.args = list(color=NA),
    centrality.point.args = list(size=2),
    package = "ggsci",
    palette = "nrc_npg"
  )

# t.test rstatix

d <- places %>% 
  dplyr::mutate(x = get(metrics[i])) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>% 
  dplyr::select(case, experiment_name, name_ext, x) %>% 
  dplyr::group_by(experiment_name, name_ext) %>%
  # rstatix::t_test(x ~ case, ref.group = "2", paired = F, var.equal = F, detailed = T) %>% 
  rstatix::wilcox_test(x ~ case, ref.group = "2", paired = F, detailed = T) %>% 
  rstatix::add_significance() 

d %>% 
  dplyr::select(experiment_name, name_ext, estimate, p, conf.low, conf.high, p.signif) %>% 
  xtable::xtable()

d %>% 
  dplyr::mutate(p.signif = factor(p.signif, levels = c("ns","*","**","***","****"))) %>% 
  ggplot2::ggplot()+
  ggplot2::geom_text(
    ggplot2::aes(x=experiment_name, y=name_ext, label=round(statistic, 2)), 
    hjust=1, vjust=0)+
  ggplot2::geom_text(
    ggplot2::aes(x=experiment_name, y=name_ext, label=round(p,2), color=p.signif), 
    hjust=0, vjust=1, size=3)
  ggnewscale::new_scale_color()+
  ggplot2::geom_text(
    ggplot2::aes(x=experiment_name, y=name_ext, label=p.signif, color=p.signif), 
    hjust=0, vjust=-0.5, size=3)

# number of runs
# for buildings => sigma / mu

# t.test native
places %>% 
  dplyr::mutate(x = get(metrics[i])) %>%
  dplyr::bind_rows(baseline, .id = "case") %>%
  dplyr::mutate(case = as.numeric(case)) %>% 
  dplyr::select(case, experiment_name, name_ext, x) %>% 
  tidyr::pivot_wider(names_from=case, names_prefix="x", values_from = x, values_fn = list) %>% 
  dplyr::mutate(
    mod = purrr::map2(x1, x2, t.test, alternative = "two.sided", var.equal = FALSE),
    statistic = purrr::map_dbl(mod, "statistic"),
    pvalue = purrr::map_dbl(mod, "p.value"),
    report = purrr::map(mod, report::report)
  ) %>% 
  ggplot2::ggplot()+
  # ggridges::geom_
  #   ggplot2::aes(x=experiment_name, y=name_ext,
  # )+
  ggplot2::geom_text(
    ggplot2::aes(x=experiment_name, y=name_ext, label=round(statistic,digits[i])), 
    hjust=1, vjust=0)+
  ggplot2::geom_text(
    ggplot2::aes(x=experiment_name, y=name_ext, label=round(pvalue,2), color=pvalue < 0.05), 
    hjust=0, vjust=1, size=3)
  # ggplot2::scale_alpha_continuous(range=c(0.5, 1.0))
  # ggplot2::scale_color_viridis_c()

### PLACES CLUSTERING --------------------------------------------------------------

## clustering
library(mclust)

places %>% 
  dplyr::mutate(x = get(metrics[i])) %>% 
  dplyr::filter(experiment_id %in% c(7)) %>%
  dplyr::group_by(name_ext) %>% 
  dplyr::mutate(
    clss = mclust::Mclust(x, G = 1:3, model="E", verbose = F)$classification
  ) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_density(ggplot2::aes(x=x, fill=factor(clss)), alpha=0.2, bw=0.02)+
  ggplot2::geom_histogram(ggplot2::aes(x=x), alpha=0.2, bins=50)+
  # ggplot2::geom_rug(ggplot2::aes(x=x, color=factor(clss)))+
  ggplot2::facet_wrap(.~name_ext, scales="fixed")



places %>% 
  dplyr::filter(experiment_id %in% c(1)) %>%
  dplyr::group_by(experiment_name, name_ext) %>% 
  dplyr::mutate(
    x = get(metrics[i]),
    g = cut(x, density(x)$x)
  ) %>% 
  dplyr::ungroup() %>% 
  dplyr::group_by(experiment_name, name_ext, g) %>% 
  dplyr::mutate(
    tmp = mean(infective_people_mean),
    cat = cut(tmp, c(0.0, 0.1, 2.0), include.lowest=T)
  ) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  ggridges::geom_density_ridges_gradient(
    # data = . %>% dplyr::filter(experiment_id != 1),
    ggplot2::aes(x=x, y=experiment_name, fill=tmp, height = ..scaled..),
    alpha=0.5, scale=0.5, size=0.2, color=NA, show.legend = T, stat="density", na.rm=T
  )+
  ggplot2::facet_grid(cols=dplyr::vars(name_ext), scales="free_x")


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
  dplyr::mutate(experiment_id = as.numeric(experiment_id))


## PEOPLE INFECTION RISK -----------------------------------------------------------------

# density plot
people %>% 
  # dplyr::filter(experiment_id %in% c(1,4)) %>%
  ggplot2::ggplot()+
  ggplot2::geom_freqpoly(ggplot2::aes(x=infection_risk_max, 
                                      y=ggplot2::after_stat(density), color=experiment_name),
                          alpha=1, bins=50)+
  ggplot2::facet_wrap(.~department, scales = "free", ncol=3)+
  ggplot2::scale_color_manual(values=palette_experiments)+
  ggplot2::guides(fill=ggplot2::guide_legend(override.aes = list(alpha=1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(legend.position = "right")

# box plot
people %>% 
  # dplyr::filter(experiment_id %in% c(1,4)) %>%
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=experiment_name, y=infection_risk_max))+
  ggplot2::facet_grid(rows=dplyr::vars(department), scales = "fixed")+
  ggplot2::guides(fill=ggplot2::guide_legend(override.aes = list(alpha=1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(legend.position = "top")


## PEOPLE CO2 LEVEL -----------------------------------------------------------------

# density plot
people %>% 
  dplyr::filter(name != "home") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_freqpoly(ggplot2::aes(x=CO2_level_mean, y=ggplot2::after_stat(density), color=experiment_name),
                         alpha=1, bins=50)+
  ggplot2::facet_wrap(.~department, scales = "free", ncol=3)+
  ggplot2::guides(fill=ggplot2::guide_legend(override.aes = list(alpha=1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(legend.position = "top")

# box plot
people %>% 
  dplyr::filter(name != "home") %>% 
  ggplot2::ggplot()+
  ggplot2::geom_boxplot(ggplot2::aes(x=experiment_name, y=CO2_level_mean))+
  ggplot2::facet_wrap(.~department, scales = "free", ncol=3)+
  ggplot2::guides(fill=ggplot2::guide_legend(override.aes = list(alpha=1)))+
  ggplot2::theme_bw()+
  ggplot2::theme(legend.position = "top")



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
  # dplyr::mutate(x = CO2_level_max) %>%
  dplyr::mutate(x = quanta_level_max) %>%
  dplyr::filter(x > 0) %>% 
  dplyr::slice(rep(dplyr::row_number(), nsamples)) %>%
  dplyr::mutate(sample = floor((dplyr::row_number()-1) / nmax) ) %>% 
  # dplyr::filter(name != "open_office_B") %>% 
  # dplyr::filter(name != "open_office_C") %>% 
  dplyr::group_by(sample, experiment_name, name_ext) %>% 
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
  # ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, CO_2 \\, (ppm)$"))+
  ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, Quanta \\, (ppm)$"))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    strip.text.x = ggplot2::element_text(angle=0, hjust=0.5, vjust=0, size=8),
    strip.text.y = ggplot2::element_text(angle=0, hjust=0, vjust=0.5, size=8),
    strip.background = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size=6),
    axis.title = ggplot2::element_text(size=8)
  ) -> g

ggplot2::ggsave("cv_places.pdf", width=9, height=11.5, device = cairo_pdf)

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
  ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;mean \\, CO_2 \\, (ppm)$"))+
  # ggplot2::labs(x="Number of simulations", y=latex2exp::TeX("$Coefficient\\,of\\,Variation:\\;max \\, Quanta \\, inhaled \\, (quanta)$"))+
  ggplot2::theme_bw()+
  ggplot2::theme(
    plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    strip.text.x = ggplot2::element_text(angle=0, hjust=0.5, vjust=0, size=8),
    strip.text.y = ggplot2::element_text(angle=0, hjust=0, vjust=0.5, size=8),
    strip.background = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size=6),
    axis.title = ggplot2::element_text(size=8)
  ) -> g

ggplot2::ggsave("cv_people.pdf", width=9, height=7, device = cairo_pdf)



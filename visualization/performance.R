library(magrittr)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')
Sys.setenv(LANG = "en_US.UTF-8")

df <- data.table::fread("../experiments/performance.csv")

num_places <- df$num_places %>% unique
num_events <- df$num_events %>% unique

df %>% 
  dplyr::mutate(time_unitary = time / number_runs) %>% 
  dplyr::group_by(num_people, num_places) %>% 
  dplyr::mutate(
    time_mean = mean(time_unitary), 
    time_sd = sd(time_unitary),
    time_max = max(time_unitary),
    time_min = min(time_unitary),
    time_upper = time_mean + time_sd,
    time_lower = time_mean - time_sd,
  ) %>% 
  dplyr::ungroup() %>% 
  ggplot2::ggplot()+
  # ggplot2::geom_point(ggplot2::aes(x=num_people, y=time_unitary))+
  # ggplot2::geom_point(ggplot2::aes(x=num_people, y=time_mean, color=as.factor(num_places)))+
  # ggplot2::geom_line(ggplot2::aes(x=num_people, y=time_mean, color=as.factor(num_places)), size=1)+
  ggplot2::geom_pointrange(ggplot2::aes(x=num_people, y=time_mean, 
                                        ymin=time_min, ymax=time_max, color=as.factor(num_places)), 
                           size=0.1)+
  ggplot2::geom_ribbon(ggplot2::aes(x=num_people, ymin=time_min, ymax=time_max, fill=as.factor(num_places)), alpha=0.1)+
  ggplot2::geom_smooth(ggplot2::aes(x=num_people, y=time_mean), method='lm', formula = 'y ~ 0 + x', 
                       size=0.1, linetype="dashed", se=F, color="black", na.rm=T)+
  # ggpmisc::stat_poly_eq(
  #   ggplot2::aes(x=num_people, y=time_mean, label = paste(..eq.label.., ..rr.label.., sep = "~~~")),
  #   formula = y~x+0, eq.with.lhs = "hat(time)~`=`~", eq.x.rhs = "~people", parse = T,) +
  # ggplot2::geom_text(x = 0, y = 6, label=latex2exp::TeX("$\\hat{y} = 2.4·10^{-3} \\; x$"), hjust=0, check_overlap = T)+
  ggplot2::scale_y_continuous(n.breaks = 6, limits=c(0, NA))+
  ggplot2::labs(
    x = "Number of people",
    y = "Time per simulation (s)",
    fill = "Number of\nplaces",
    color = "Number of\nplaces"
    # caption = paste("simulated", num_places, "places, and with", num_events, "events available."),
  )+
  ggsci::scale_color_jama()+
  ggsci::scale_fill_locuszoom()+
  ggplot2::theme_bw()+
  ggplot2::theme(
    legend.position = c(0.9, 0.3),
    legend.background = ggplot2::element_blank(),
    # plot.margin = grid::unit(c(0, 0, 0, 0), "null"),
    panel.spacing = grid::unit(c(0, 0, 0, 0), "null"),
  )

ggplot2::ggsave("performance.pdf", width=6, height=4, device = cairo_pdf)


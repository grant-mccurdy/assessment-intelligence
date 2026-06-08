#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
})

source("R/plots/plot_theme.R")

hex_round <- function(q, r) {
  x <- q
  z <- r
  y <- -x - z

  rx <- round(x)
  ry <- round(y)
  rz <- round(z)

  x_diff <- abs(rx - x)
  y_diff <- abs(ry - y)
  z_diff <- abs(rz - z)

  adjust_x <- x_diff > y_diff & x_diff > z_diff
  adjust_y <- !adjust_x & y_diff > z_diff
  adjust_z <- !adjust_x & !adjust_y

  rx[adjust_x] <- -ry[adjust_x] - rz[adjust_x]
  ry[adjust_y] <- -rx[adjust_y] - rz[adjust_y]
  rz[adjust_z] <- -rx[adjust_z] - ry[adjust_z]

  data.frame(q = rx, r = rz)
}

build_hexbin_polygons <- function(data, x_col, y_col, xlim, ylim, bins = 34L) {
  x <- data[[x_col]]
  y <- data[[y_col]]
  x_span <- diff(xlim)
  y_span <- diff(ylim)
  x_norm <- (x - xlim[[1]]) / x_span
  y_norm <- (y - ylim[[1]]) / y_span
  keep <- is.finite(x_norm) & is.finite(y_norm) &
    x_norm >= 0 & x_norm <= 1 & y_norm >= 0 & y_norm <= 1

  size <- 1 / (sqrt(3) * bins)
  q_raw <- (sqrt(3) / 3 * x_norm[keep] - 1 / 3 * y_norm[keep]) / size
  r_raw <- (2 / 3 * y_norm[keep]) / size
  rounded <- hex_round(q_raw, r_raw)

  hex_counts <- rounded %>%
    count(q, r, name = "count") %>%
    mutate(
      hex_id = row_number(),
      center_x_norm = size * sqrt(3) * (q + r / 2),
      center_y_norm = size * 3 / 2 * r
    )

  angles <- pi / 6 + (0:5) * pi / 3
  bind_rows(lapply(seq_len(nrow(hex_counts)), function(index) {
    row <- hex_counts[index, ]
    vertex_x_norm <- row$center_x_norm + size * cos(angles)
    vertex_y_norm <- row$center_y_norm + size * sin(angles)
    data.frame(
      hex_id = row$hex_id,
      count = row$count,
      x = xlim[[1]] + vertex_x_norm * x_span,
      y = ylim[[1]] + vertex_y_norm * y_span,
      stringsAsFactors = FALSE
    )
  }))
}

plot_hexbin <- function(
    data_path = "data/synthetic/plot_catalog_dense_relationships.csv",
    output_path = "outputs/plots/hexbin_readiness_growth.png") {
  data <- read_csv(data_path, show_col_types = FALSE)
  xlim <- c(0, 100)
  ylim <- c(-22, 52)
  hex_polygons <- build_hexbin_polygons(
    data = data,
    x_col = "readiness_index",
    y_col = "growth_points",
    xlim = xlim,
    ylim = ylim,
    bins = 34L
  )

  plot <- ggplot(hex_polygons, aes(x = x, y = y, group = hex_id, fill = count)) +
    geom_polygon(color = "white", linewidth = 0.08) +
    geom_smooth(
      data = data,
      aes(x = readiness_index, y = growth_points),
      inherit.aes = FALSE,
      method = "loess",
      formula = y ~ x,
      se = FALSE,
      color = "#D55E00",
      linewidth = 0.85
    ) +
    scale_fill_gradientn(
      colors = c("#F7FBFF", "#C6DBEF", "#6BAED6", "#2171B5", "#08306B"),
      trans = "sqrt",
      labels = comma,
      name = "Responses"
    ) +
    coord_cartesian(xlim = xlim, ylim = ylim, expand = FALSE) +
    labs(
      title = "Readiness-growth density",
      subtitle = "Hexagonal bins prevent overplotting in 5,600 synthetic response events.",
      x = "Readiness index",
      y = "Growth points",
      caption = "Synthetic data only. Orange curve is descriptive, not causal."
    ) +
    theme_plot_catalog()

  save_plot_catalog(plot, output_path, width = 7.6, height = 4.9)
  invisible(plot)
}

if (identical(sys.nframe(), 0L)) {
  plot_hexbin()
}

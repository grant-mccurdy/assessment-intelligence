suppressPackageStartupMessages({
  library(ggplot2)
})

ensure_directory <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

plot_catalog_colors <- c(
  "Baseline review" = "#0072B2",
  "Targeted reteach" = "#009E73",
  "AI practice" = "#D55E00"
)

theme_plot_catalog <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(
        face = "bold",
        color = "#17212B",
        size = base_size * 1.25,
        margin = margin(b = 6)
      ),
      plot.subtitle = element_text(
        color = "#46515C",
        size = base_size * 0.98,
        margin = margin(b = 12)
      ),
      plot.caption = element_text(
        color = "#65717D",
        size = base_size * 0.88,
        hjust = 0,
        margin = margin(t = 10)
      ),
      axis.title = element_text(color = "#2D3740", size = base_size),
      axis.text = element_text(color = "#46515C"),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
}

save_plot_catalog <- function(plot, output_path, width = 7.4, height = 4.8, dpi = 320) {
  ensure_directory(dirname(output_path))
  ggsave(
    filename = output_path,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  invisible(output_path)
}

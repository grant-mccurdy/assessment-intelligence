#!/usr/bin/env Rscript

source("R/plots/plot_raincloud.R")
source("R/plots/plot_hexbin.R")
source("R/plots/plot_calibration.R")

plot_raincloud()
plot_hexbin()
plot_calibration()

message("Rendered plot catalog images to outputs/plots")

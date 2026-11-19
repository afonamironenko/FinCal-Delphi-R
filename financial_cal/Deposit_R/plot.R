# Draws a chart from the CSV file that the Delphi program writes.
#
# Usage:  Rscript plot.R <input_csv> <output_png>
#
# Delphi passes both paths itself. If you run the script by hand without
# arguments, paths relative to the project folder are used, so start it from
# the project root:  Rscript Deposit_R/plot.R
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
csv_path <- if (length(args) >= 1) args[1] else file.path("CSV_files", "data.csv")
png_path <- if (length(args) >= 2) args[2] else file.path("Deposit_R", "chart.png")

data_from_delphi_finance <- read.csv(csv_path, sep = ";")
#file was prepared

graphic <- ggplot(data_from_delphi_finance, aes(x = period, y = balance)) + geom_line(linewidth = 1.5, colour = "green") + geom_point(size = 2) + labs(title = "Amount of money", x = 'Period', y = "Finance") + theme_minimal()
ggsave(png_path, plot = graphic, width = 10, height = 6, dpi = 100)

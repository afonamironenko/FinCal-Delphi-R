# FinCal

A financial calculator written in Delphi (VCL) with charts drawn by R (ggplot2).

## Features

- **Deposit | Invest** - compound interest on a deposit (daily / monthly / yearly)
- **Credit** - annuity payment and remaining balance
- **Bonds** - approximate yield (YTM) and growth of a bond
- **NPV** - net present value with inflation

Each calculation is shown in a Delphi `TChart` and saved to `CSV_files/data.csv`.
Then `Rscript` runs `Deposit_R/plot.R`, which draws `Deposit_R/chart.png`, and the picture is shown in the program.

## Requirements

- Windows
- Embarcadero Delphi (RAD Studio) with VCL and TeeChart
- [R](https://www.r-project.org/) with the `ggplot2` package:
  ```r
  install.packages("ggplot2")
  ```

## How to run

1. Clone the repository.
2. Open `FinCal.dproj` in Delphi.
3. Build and run (F9).

No paths need to be edited: the program finds its project folder and R by itself (see below).

## How the program finds files

- **Project folder:** it starts from the folder of the `.exe` (for example `Win32\Debug`) and goes up
  until it finds `Deposit_R\plot.R`.
- **R:** the path to `Rscript.exe` is read from the Windows registry (the R installer writes it there).
  If it is not found, `Rscript.exe` from `PATH` is used.

## Project structure

| Path | What it is |
|------|------------|
| `FinCal.dpr` | Program entry point |
| `FinCalMain.pas` / `FinCalMain.dfm` | Main form: code and visual design |
| `FinCal.dproj` | Delphi project settings |
| `FinCal.res` | Program resources (icon, version info) |
| `Deposit_R/plot.R` | R script that draws the chart |
| `CSV_files/` | Folder where the program writes `data.csv` for R |

## Known issues

- If R is not installed, the chart is not drawn.

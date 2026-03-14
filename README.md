# 🌍 Disaster Dash

**Global Disaster Impact & Humanitarian Aid  ·  2018–2024**

An interactive R Shiny dashboard for exploring disaster frequency, economic losses, and humanitarian aid coverage across 20 countries and 10 disaster types.

🔗 **Live App:** [https://your-shinyapps-link-here](https://your-shinyapps-link-here)

---

## Features

- **Choropleth map** — visualize disaster frequency, economic loss, casualties, or aid coverage by country
- **KPI cards** — total unfunded disaster losses and median disaster burden as % of GDP
- **Bar charts** — economic loss and aid amount by disaster type, with configurable summary statistic
- **Sidebar filters** — filter by country, disaster type, date range, map metric, and bar chart statistic

---

## Prerequisites

- [R](https://cran.r-project.org/) (≥ 4.2)
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended, but optional)

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

### 2. Install R package dependencies

Open R or RStudio and run:

```r
install.packages(c("shiny", "dplyr", "plotly", "bslib"))
```

---

## Project Structure

```
your-repo/
├── app.R                                        # Main Shiny application
├── data/
│   └── global_disaster_response_2018_2024.csv  # Dataset
└── README.md
```

---

## Running Locally

### Option A — RStudio

1. Open `app.R` in RStudio
2. Click the **Run App** button in the top-right of the editor pane

### Option B — R Console

```r
shiny::runApp("path/to/your-repo")
```

### Option C — Terminal

```bash
Rscript -e "shiny::runApp('.')"
```

The app will open in your browser at `http://127.0.0.1:XXXX`.

---

## Usage

| Control | Description |
|---|---|
| **Countries** | Multi-select filter; defaults to Brazil, Bangladesh, South Africa |
| **Disaster Type** | Multi-select filter across 10 disaster categories |
| **Date Range** | Restrict events to a date window within 2018–2024 |
| **Map Metric** | Choose what the choropleth colour encodes |
| **Bar Chart Statistic** | Aggregate bars by sum, mean, min, or max |
| **Reset All Filters** | Restore all controls to their defaults |

---

## Authors

Ojasv Issar, Joel Nicholas Peterson, Claire Saunders

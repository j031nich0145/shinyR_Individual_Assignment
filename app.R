# app.R — Disaster Dash (Minimal R Shiny)
# Global Disaster Impact & Humanitarian Aid (2018–2024)
#
# Dependencies: shiny, dplyr, plotly, bslib
# Data:         data/global_disaster_response_2018_2024.csv (relative to this file)

library(shiny)
library(dplyr)
library(plotly)
library(bslib)

# ── Helper functions ────────────────────────────────────────────────────────────
fmt_currency <- function(v) {
  sign <- if (v < 0) "-" else ""
  v    <- abs(v)
  if (v >= 1e12) return(paste0(sign, "$", formatC(v / 1e12, digits = 2, format = "f"), "T"))
  if (v >= 1e9)  return(paste0(sign, "$", formatC(v / 1e9,  digits = 1, format = "f"), "B"))
  if (v >= 1e6)  return(paste0(sign, "$", formatC(v / 1e6,  digits = 1, format = "f"), "M"))
  if (v >= 1e3)  return(paste0(sign, "$", formatC(v / 1e3,  digits = 1, format = "f"), "K"))
  paste0(sign, "$", round(v))
}

fmt_num <- function(v) {
  if (v >= 1e6) return(paste0(formatC(v / 1e6, digits = 1, format = "f"), "M"))
  if (v >= 1e3) return(paste0(formatC(v / 1e3, digits = 1, format = "f"), "K"))
  formatC(v, format = "d", big.mark = ",")
}

# ── Constants ───────────────────────────────────────────────────────────────────
ISO3 <- c(
  "Australia" = "AUS", "Bangladesh" = "BGD", "Brazil"       = "BRA",
  "Canada"    = "CAN", "Chile"      = "CHL", "China"        = "CHN",
  "France"    = "FRA", "Germany"    = "DEU", "Greece"       = "GRC",
  "India"     = "IND", "Indonesia"  = "IDN", "Italy"        = "ITA",
  "Japan"     = "JPN", "Mexico"     = "MEX", "Nigeria"      = "NGA",
  "Philippines" = "PHL", "South Africa" = "ZAF", "Spain"    = "ESP",
  "Turkey"    = "TUR", "United States" = "USA"
)

GDP <- c(
  "Australia"     = 1757022451652.83,  "Bangladesh"    = 450119432068.85,
  "Brazil"        = 2185821648943.86,  "Canada"        = 2243636826633.76,
  "Chile"         = 330267137371.59,   "China"         = 18743803170827.20,
  "Germany"       = 4685592577804.69,  "Spain"         = 1725671652742.19,
  "France"        = 3160442622465.08,  "Greece"        = 256238371778.12,
  "Indonesia"     = 1396300098190.97,  "India"         = 3909891533858.08,
  "Italy"         = 2380825077243.59,  "Japan"         = 4027597523550.58,
  "Mexico"        = 1856365616165.94,  "Nigeria"       = 252261880141.15,
  "Philippines"   = 461617509782.36,   "United States" = 28750956130731.20,
  "South Africa"  = 401144998373.59
)

COUNTRIES      <- sort(names(ISO3))
DISASTER_TYPES <- c("Drought","Earthquake","Extreme Heat","Flood","Hurricane",
                    "Landslide","Storm Surge","Tornado","Volcanic Eruption","Wildfire")

MAP_METRICS <- c(
  "disasters"    = "Disaster Frequency",
  "coverage_pct" = "Aid Coverage (%)",
  "total_loss"   = "Economic Loss (USD)",
  "casualties"   = "Total Casualties"
)

SUMMARY_CHOICES <- c("sum" = "Total Sum", "mean" = "Average",
                     "min" = "Minimum",   "max"  = "Maximum")

QUESTION_MAP <- c(
  "total_loss"   = "Where are disasters causing the highest economic losses?",
  "coverage_pct" = "Where are disaster losses least covered by aid?",
  "disasters"    = "Where are disasters occurring most frequently?",
  "casualties"   = "Where are disasters causing the greatest loss of life?"
)

# ── Data ────────────────────────────────────────────────────────────────────────
df      <- read.csv("data/global_disaster_response_2018_2024.csv")
df$date <- as.Date(df$date)

# ── UI ──────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  tags$head(tags$style(HTML("
    body { background: #eef2f7; font-family: 'Segoe UI', sans-serif; }
    .kpi-box { background: #fff; border: 1px solid #dde4ee; border-radius: 12px;
               padding: 18px 16px; margin-bottom: 12px; }
    .kpi-label { font-size: 0.65rem; font-weight: 700; text-transform: uppercase;
                 letter-spacing: 1px; color: #64748b; margin-bottom: 4px; }
    .kpi-value { font-size: 2rem; font-weight: 700; margin: 2px 0; color: #0f172a; }
    .kpi-sub   { font-size: 0.78rem; color: #475569; margin: 0; }
    .kpi-form  { font-size: 0.68rem; color: #94a3b8; font-family: monospace; }
    .sidebar-panel { background: #fff; border-right: 1px solid #dde4ee; }
  "))),

  titlePanel(
    div(
      span("🌍", style = "margin-right:10px; font-size:1.5rem;"),
      strong("Disaster Dash"),
      span(" — Global Disaster Impact & Humanitarian Aid  ·  2018–2024",
           style = "font-size:0.9rem; color:#64748b; font-weight:400;")
    )
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("countries", "Countries",
                  choices  = COUNTRIES,
                  selected = c("Brazil", "Bangladesh", "South Africa"),
                  multiple = TRUE),
      selectInput("disaster_type", "Disaster Type",
                  choices  = DISASTER_TYPES,
                  selected = DISASTER_TYPES,
                  multiple = TRUE),
      dateRangeInput("date_range", "Date Range",
                     start = "2018-01-01", end = "2024-12-31",
                     min   = "2018-01-01", max = "2024-12-31"),
      selectInput("map_metric", "Map Metric",
                  choices  = MAP_METRICS,
                  selected = "total_loss"),
      selectInput("summary_stat", "Bar Chart Statistic",
                  choices  = SUMMARY_CHOICES,
                  selected = "sum"),
      hr(),
      actionButton("reset", "↺  Reset All Filters",
                   class = "btn-outline-danger btn-sm w-100")
    ),

    mainPanel(
      width = 9,

      # Row 1: Map + KPIs
      fluidRow(
        column(8, plotlyOutput("map_plot", height = "380px")),
        column(4,
          uiOutput("kpi_gap"),
          uiOutput("kpi_coverage")
        )
      ),

      br(),

      # Row 2: Bar charts
      fluidRow(
        column(6, plotlyOutput("bar_loss", height = "320px")),
        column(6, plotlyOutput("bar_aid",  height = "320px"))
      )
    )
  )
)

# ── Server ───────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # Reset button
  observeEvent(input$reset, {
    updateSelectInput(session, "countries",     selected = c("Brazil", "Bangladesh", "South Africa"))
    updateSelectInput(session, "disaster_type", selected = DISASTER_TYPES)
    updateDateRangeInput(session, "date_range", start = "2018-01-01", end = "2024-12-31")
    updateSelectInput(session, "map_metric",    selected = "total_loss")
    updateSelectInput(session, "summary_stat",  selected = "sum")
  })

  # Filtered data
  filtered <- reactive({
    req(input$countries, input$disaster_type, input$date_range)
    df |>
      filter(
        country      %in% input$countries,
        disaster_type %in% input$disaster_type,
        date >= input$date_range[1],
        date <= input$date_range[2]
      )
  })

  # ── KPI: Total Unfunded Gap ─────────────────────────────────────────────────
  output$kpi_gap <- renderUI({
    data <- filtered()
    val  <- if (nrow(data) == 0) "—" else fmt_currency(sum(data$economic_loss_usd) - sum(data$aid_amount_usd))
    div(class = "kpi-box",
      div("Total Unfunded Disaster Losses", class = "kpi-label"),
      div(val, class = "kpi-value"),
      p("Disaster losses not covered by aid", class = "kpi-sub"),
      p("Loss − Aid", class = "kpi-form")
    )
  })

  # ── KPI: Disaster Burden % GDP ──────────────────────────────────────────────
  output$kpi_coverage <- renderUI({
    data <- filtered()
    val  <- if (nrow(data) == 0) {
      "—"
    } else {
      agg <- data |>
        group_by(country) |>
        summarise(loss = sum(economic_loss_usd), aid = sum(aid_amount_usd), .groups = "drop") |>
        mutate(gap = loss - aid, gdp = GDP[country], gap_pct = gap / gdp * 100)
      sprintf("%.2f%%", median(agg$gap_pct, na.rm = TRUE))
    }
    div(class = "kpi-box",
      div("Disaster Burden (% of GDP)", class = "kpi-label"),
      div(val, class = "kpi-value"),
      p("Typical funding gap relative to GDP", class = "kpi-sub"),
      p("Median((Loss − Aid) ÷ GDP)", class = "kpi-form")
    )
  })

  # ── Choropleth Map ──────────────────────────────────────────────────────────
  output$map_plot <- renderPlotly({
    data   <- filtered()
    metric <- input$map_metric

    validate(need(nrow(data) > 0, "No data — adjust your filters."))

    agg <- data |>
      group_by(country) |>
      summarise(
        disasters  = n(),
        casualties = sum(casualties),
        total_loss = sum(economic_loss_usd),
        total_aid  = sum(aid_amount_usd),
        .groups = "drop"
      ) |>
      mutate(
        iso3         = ISO3[country],
        coverage_pct = ifelse(total_loss > 0, total_aid / total_loss * 100, NA_real_),
        loss_fmt     = sapply(total_loss,  fmt_currency),
        aid_fmt      = sapply(total_aid,   fmt_currency),
        cas_fmt      = formatC(casualties, format = "d", big.mark = ","),
        cov_fmt      = ifelse(!is.na(coverage_pct), sprintf("%.1f%%", coverage_pct), "N/A"),
        hover        = paste0(
          "<b>", country, "</b><br>",
          "Events: ",    disasters, "<br>",
          "Casualties: ", cas_fmt,  "<br>",
          "Econ Loss: ",  loss_fmt, "<br>",
          "Aid: ",        aid_fmt,  "<br>",
          "Coverage: ",   cov_fmt
        )
      )

    plot_geo(agg, locations = ~iso3) |>
      add_trace(
        z          = agg[[metric]],
        text       = ~hover,
        hoverinfo  = "text",
        colorscale = "Viridis",
        marker     = list(line = list(color = "#94a3b8", width = 0.5)),
        colorbar   = list(title = MAP_METRICS[metric], thickness = 12, len = 0.55)
      ) |>
      layout(
        title = list(text = QUESTION_MAP[metric], font = list(size = 12, color = "#64748b")),
        geo = list(
          projection    = list(type = "natural earth"),
          fitbounds     = "locations",
          showframe     = FALSE,
          showcountries = TRUE,  countrycolor  = "#64748b",
          showcoastlines = TRUE, coastlinecolor = "#64748b",
          showland      = TRUE,  landcolor      = "#e8edf4",
          showocean     = TRUE,  oceancolor     = "#dbeafe",
          bgcolor       = "rgba(0,0,0,0)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        margin        = list(l = 0, r = 0, t = 30, b = 0)
      )
  })

  # ── Bar Chart Helper ────────────────────────────────────────────────────────
  make_bar <- function(column, y_label) {
    data <- filtered()
    validate(need(nrow(data) > 0, "No data — adjust your filters."))

    stat_fn <- switch(input$summary_stat, sum = sum, mean = mean, min = min, max = max)
    stat_lbl <- SUMMARY_CHOICES[input$summary_stat]

    grp <- data |>
      group_by(disaster_type) |>
      summarise(val = stat_fn(.data[[column]]), .groups = "drop") |>
      arrange(desc(val)) |>
      mutate(fmt = sapply(val, fmt_currency))

    plot_ly(grp,
      x = ~disaster_type, y = ~val, type = "bar",
      text = ~fmt, textposition = "outside",
      hovertemplate = paste0("<b>%{x}</b><br>", y_label, ": %{text}<extra></extra>"),
      marker = list(
        color     = ~val,
        colorscale = list(c(0, "#0d9488"), c(1, "#134e4a")),
        showscale = FALSE
      )
    ) |>
      layout(
        title       = list(text = paste0(y_label, "  <i style='font-size:10px'>(", stat_lbl, ")</i>"),
                           font = list(size = 12, color = "#64748b")),
        xaxis       = list(title = "", tickfont = list(size = 9)),
        yaxis       = list(title = y_label, tickfont = list(size = 9), gridcolor = "#dde4ee"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        showlegend    = FALSE,
        margin        = list(l = 60, r = 20, t = 40, b = 80)
      )
  }

  output$bar_loss <- renderPlotly(make_bar("economic_loss_usd", "Economic Loss (USD)"))
  output$bar_aid  <- renderPlotly(make_bar("aid_amount_usd",    "Aid Amount (USD)"))
}

shinyApp(ui, server)

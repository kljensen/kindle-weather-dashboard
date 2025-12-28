// Kindle Weather Dashboard
// 758x1024 pixels for Kindle e-ink display

#set page(
  width: 758pt,
  height: 1024pt,
  margin: 24pt,
  fill: white,
)

#let base-font-size = 16pt

#set text(
  font: ("Helvetica Neue", "Helvetica", "Arial"),
  size: base-font-size,
  fill: black,
)

// Load weather data
#let data = json("weather_data.json")

// Helper: Convert Fahrenheit to Celsius
#let f_to_c(f) = {
  calc.round((f - 32) * 5 / 9)
}

// Helper: Get weather icon path from WMO code
#let weather_icon(code) = {
  let icons = (
    "0": "sun.svg", // Clear sky
    "1": "sun-cloud.svg", // Mainly clear
    "2": "sun-cloud.svg", // Partly cloudy
    "3": "clouds.svg", // Overcast
    "45": "fog.svg", // Fog
    "48": "fog.svg", // Depositing rime fog
    "51": "cloud-rain.svg", // Drizzle light
    "53": "cloud-rain.svg", // Drizzle moderate
    "55": "cloud-rain.svg", // Drizzle dense
    "56": "cloud-sleet.svg", // Freezing drizzle light
    "57": "cloud-sleet.svg", // Freezing drizzle dense
    "61": "cloud-rain.svg", // Rain slight
    "63": "cloud-rain.svg", // Rain moderate
    "65": "cloud-rain.svg", // Rain heavy
    "66": "cloud-sleet.svg", // Freezing rain light
    "67": "cloud-sleet.svg", // Freezing rain heavy
    "71": "cloud-snow.svg", // Snow slight
    "73": "cloud-snow.svg", // Snow moderate
    "75": "cloud-snow.svg", // Snow heavy
    "77": "cloud-snow.svg", // Snow grains
    "80": "sun-cloud-rain.svg", // Rain showers slight
    "81": "sun-cloud-rain.svg", // Rain showers moderate
    "82": "cloud-rain.svg", // Rain showers violent
    "85": "sun-cloud-snow.svg", // Snow showers slight
    "86": "cloud-snow.svg", // Snow showers heavy
    "95": "sun-cloud-lightning.svg", // Thunderstorm
    "96": "cloud-hail.svg", // Thunderstorm with hail
    "99": "cloud-hail.svg", // Thunderstorm with heavy hail
  )
  let code_str = str(code)
  if code_str in icons {
    "icons/" + icons.at(code_str)
  } else {
    "icons/sun.svg"
  }
}

// Helper: Get weather description from WMO code
#let weather_desc(code) = {
  let descriptions = (
    "0": "Clear",
    "1": "Mostly Clear",
    "2": "Partly Cloudy",
    "3": "Overcast",
    "45": "Foggy",
    "48": "Foggy",
    "51": "Light Drizzle",
    "53": "Drizzle",
    "55": "Heavy Drizzle",
    "56": "Freezing Drizzle",
    "57": "Freezing Drizzle",
    "61": "Light Rain",
    "63": "Rain",
    "65": "Heavy Rain",
    "66": "Freezing Rain",
    "67": "Freezing Rain",
    "71": "Light Snow",
    "73": "Snow",
    "75": "Heavy Snow",
    "77": "Snow Grains",
    "80": "Light Showers",
    "81": "Showers",
    "82": "Heavy Showers",
    "85": "Snow Showers",
    "86": "Heavy Snow",
    "95": "Thunderstorm",
    "96": "Thunderstorm",
    "99": "Severe Storm",
  )
  let code_str = str(code)
  if code_str in descriptions {
    descriptions.at(code_str)
  } else {
    "Unknown"
  }
}

// Helper: Parse ISO date or datetime string to datetime object
#let parse_iso(iso_str) = {
  // Handle both "2025-12-27" and "2025-12-27T14:45" formats
  let date_part = iso_str.split("T").at(0)
  let parts = date_part.split("-")
  datetime(
    year: int(parts.at(0)),
    month: int(parts.at(1)),
    day: int(parts.at(2)),
  )
}

// Helper: Format day name from ISO date/datetime
#let day_name(iso_str) = {
  parse_iso(iso_str).display("[weekday repr:short]")
}

// Helper: Format full date from ISO date/datetime
#let format_date(iso_str) = {
  let d = parse_iso(iso_str)
  (
    weekday: d.display("[weekday]"),
    day: d.display("[day]"),
    month: d.display("[month repr:long]"),
  )
}

// Extract data
#let current_temp_f = calc.round(data.current.temperature_2m)
#let current_temp_c = f_to_c(data.current.temperature_2m)
#let current_code = data.current.weather_code
#let today_high = calc.round(data.daily.temperature_2m_max.at(0))
#let today_low = calc.round(data.daily.temperature_2m_min.at(0))
#let today_date = format_date(data.current.time)

// Get hourly precip for today (first 24 hours)
#let hourly_precip = data.hourly.precipitation_probability.slice(0, 24)

// Days 1-7 (tomorrow through 7 days out)
#let forecast_days = range(1, 8)

// ============================================================================
// MAIN LAYOUT - Vertical Grid
// ============================================================================
#grid(
  columns: (1fr,),
  rows: (1fr, 1.4fr, 1.4fr, auto),
  row-gutter: 0pt,

  // ============================================================================
  // HERO SECTION
  // ============================================================================
  [
    #box(width: 100%, height: 100%, inset: (y: 1em))[
      #grid(
        columns: (1fr, 1fr, 1fr),
        align: (left + horizon, center + horizon, right + horizon),
        // Left: Date
        [
          #set par(leading: 0pt)
          #set text(top-edge: "cap-height", bottom-edge: "baseline")
          #context {
            // Measure the width of the day number to align other elements
            let day-text = text(size: 4.5em, weight: "bold")[#today_date.day]
            let day-width = measure(day-text).width
            box(width: day-width)[#text(size: 1.5em, weight: "medium")[#today_date.weekday]]
            linebreak()
            day-text
            linebreak()
            box(width: day-width)[#text(size: 1.25em, weight: "light")[#today_date.month]]
          }
        ],
        // Center: Icon + Condition
        [
          #align(center)[
            #image(weather_icon(current_code), width: 6em)
            #v(-0.25em)
            #text(size: 1em)[#weather_desc(current_code)]
          ]
        ],
        // Right: Temperature
        [
          #align(right)[
            #set par(leading: 0pt)
            #set text(top-edge: "cap-height", bottom-edge: "baseline")
            #text(size: 4.5em, weight: "bold")[#current_temp_f°F]\
            #text(size: 1.5em, fill: luma(80))[#current_temp_c°C]\
            #v(0.25em)
            #text(size: 1.125em)[H #today_high° #h(0.5em) L #today_low°]
          ]
        ],
      )
    ]
    #line(length: 100%, stroke: 0.5pt + black)
  ],

  // ============================================================================
  // PRECIPITATION SECTION
  // ============================================================================
  [
    #box(width: 100%, height: 100%, inset: (top: 1em))[
      #text(size: 0.875em, weight: "medium")[PRECIPITATION PROBABILITY]
      #v(0.5em)

      #let bar_width = 100% / 24

      // Bar chart container - fills remaining space
      #block(width: 100%, height: 1fr)[
        #align(bottom)[
          #stack(dir: ltr, spacing: 0pt, ..hourly_precip
            .enumerate()
            .map(((i, prob)) => {
              box(
                width: bar_width,
                height: prob * 1%,
                align(bottom)[
                  #rect(width: 80%, height: 100%, fill: black)
                ],
              )
            }))
        ]
      ]

      // X-axis labels
      #v(0.25em)
      #stack(
        dir: ltr,
        spacing: 0pt,
        ..range(0, 24, step: 3).map(h => {
          box(width: bar_width * 3, align(center)[
            #text(size: 0.7em)[#if h < 10 { "0" }#h]
          ])
        }),
      )
    ]
    #line(length: 100%, stroke: 0.5pt + black)
  ],

  // ============================================================================
  // 7-DAY FORECAST SECTION
  // ============================================================================
  [
    #box(width: 100%, height: 100%, inset: (top: 1em))[
      #text(size: 0.875em, weight: "medium")[7-DAY FORECAST]
      #v(0.75em)

      #grid(
        columns: (1fr,) * 7,
        rows: (auto, 1fr, auto, auto),
        align: center,
        row-gutter: 0.5em,
        // Day names
        ..forecast_days.map(i => {
          text(size: 0.875em, weight: "medium")[#day_name(data.daily.time.at(i))]
        }),
        // Icons
        ..forecast_days.map(i => {
          image(weather_icon(data.daily.weather_code.at(i)), width: 2.75em)
        }),
        // High temps
        ..forecast_days.map(i => {
          let high = calc.round(data.daily.temperature_2m_max.at(i))
          text(size: 1em, weight: "bold")[#high°]
        }),
        // Low temps
        ..forecast_days.map(i => {
          let low = calc.round(data.daily.temperature_2m_min.at(i))
          text(size: 0.875em, fill: luma(100))[#low°]
        }),
      )
    ]
  ],

  // ============================================================================
  // FOOTER
  // ============================================================================
  [
    #align(center)[
      #text(size: 0.7em, fill: luma(120))[
        Updated: #datetime.today().display("[month repr:short] [day], [year]")
      ]
    ]
  ],
)

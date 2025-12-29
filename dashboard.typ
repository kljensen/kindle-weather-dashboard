// Kindle Weather Dashboard
// 758x1024 pixels for Kindle e-ink display

#import "@preview/cetz:0.3.2": canvas, draw

#set page(
  width: 758pt,
  height: 1024pt,
  margin: 24pt,
  fill: white,
)

#let base-font-size = 16pt

#set text(
  font: ("Myriad Pro", "Helvetica Neue", "Helvetica", "Arial"),
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

// Helper: Determine if precipitation is snow based on WMO code
#let is_snow(code) = {
  // Snow codes: 71-77 (snow), 85-86 (snow showers)
  code >= 71 and code <= 77 or code == 85 or code == 86
}

// Helper: Get precipitation fill based on weather code
#let precip_fill(code) = {
  if is_snow(code) { luma(120) } else { black }
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

// Helper: Scale content horizontally to match a target width
#let scale_to_width(target-width, content) = {
  box(context {
    let content-width = measure(content).width
    let ratio = target-width / content-width
    scale(x: ratio * 100%, origin: left + horizon)[#content]
  })
}

// Extract data
#let current_temp_f = calc.round(data.current.temperature_2m)
#let current_temp_c = f_to_c(data.current.temperature_2m)
#let current_code = data.current.weather_code
#let today_high = calc.round(data.daily.temperature_2m_max.at(0))
#let today_low = calc.round(data.daily.temperature_2m_min.at(0))
#let today_date = format_date(data.current.time)
#let current_hour = int(data.current.time.split("T").at(1).split(":").at(0))

// Get hourly data for today (first 24 hours)
#let hourly_precip_prob = data.hourly.precipitation_probability.slice(0, 24)
#let hourly_precip = data.hourly.precipitation.slice(0, 24)
#let hourly_temps = data.hourly.temperature_2m.slice(0, 24)
#let hourly_codes = data.hourly.weather_code.slice(0, 24)

// Calculate temperature range for scaling
#let temp_min = calc.min(..hourly_temps)
#let temp_max = calc.max(..hourly_temps)
#let temp_range = calc.max(temp_max - temp_min, 10) // At least 10 degree range

// Find indices of min and max temperatures
#let temp_max_idx = hourly_temps.position(t => t == temp_max)
#let temp_min_idx = hourly_temps.position(t => t == temp_min)

// Calculate max precipitation for scaling (use at least 0.5mm to avoid division issues)
#let precip_max = calc.max(calc.max(..hourly_precip), 0.5)

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
      // Background weather icon (artsy, faded)
      #place(horizon + left, dx: 25%)[
        #let icon-size = 220%
        #box(width: icon-size, height: icon-size, clip: true)[
          #image(weather_icon(current_code), height: 100%)
          #place(top + left)[
            #rect(width: 100%, height: 100%, fill: white.transparentize(15%), stroke: none)
          ]
        ]
      ]
      #grid(
        columns: (1fr, 1fr),
        align: (left + horizon, right + horizon),
        // Left: Date
        [
          #set par(leading: 0pt)
          #set text(top-edge: "cap-height", bottom-edge: "baseline", fill: luma(170))
          #context {
            let day-text = box(inset: (y: 10pt))[#text(size: 10em, weight: 900)[#today_date.day]]
            let day-width = measure(day-text).width

            scale_to_width(day-width, text(size: 3em, weight: "light")[#today_date.weekday])
            linebreak()
            day-text
            linebreak()
            scale_to_width(day-width, text(size: 2.5em, weight: "light")[#upper(today_date.month)])
          }
        ],
        // Right: Temperature (mirrors left structure)
        [
          #set par(leading: 0pt)
          #set text(top-edge: "cap-height", bottom-edge: "baseline")
          #context {
            let temp = box(inset: (y: 10pt))[#text(size: 10em, weight: 900)[#current_temp_f]#text(size: 10em, weight: "light", fill: luma(100))[°]]
            let temp-width = measure(temp).width

            // Spacer matching Saturday's height
            hide(scale_to_width(temp-width, text(size: 3em, weight: "light")[Saturday]))
            linebreak()
            temp
            linebreak()
            box(width: temp-width)[
              #align(left)[
                #text(size: 2.5em, weight: "light", stretch: 75%)[
                ~
                Lo #today_low°
                #sym.dot.c
                Hi #today_high°
                ]
              ]
            ]
          }
        ],
      )
    ]
    #line(length: 100%, stroke: 0.5pt + black)
  ],

  // ============================================================================
  // HOURLY FORECAST SECTION (Precipitation + Temperature)
  // ============================================================================
  [
    #box(width: 100%, height: 100%, inset: (top: 1em))[
      // Header with title and legend
      #grid(
        columns: (1fr, auto),
        align: (left, right),
        text(size: 0.875em, weight: "medium")[TODAY],
        [
          #text(size: 0.7em)[
            #box(width: 0.6em, height: 0.6em, fill: black, baseline: 0.1em)
            Rain
            #h(0.5em)
            #box(width: 0.6em, height: 0.6em, fill: luma(120), baseline: 0.1em)
            Snow
            #h(0.5em)
            #box(width: 1em, height: 0pt, stroke: 1.5pt + black, baseline: 0.2em)
            Temp
          ]
        ],
      )
      #v(0.5em)

      #let bar_width = 100% / 24

      // Combined chart container - use block with 1fr, wrap content in it
      #block(width: 100%, height: 1fr)[
        // Chart area (full width)
        #box(width: 100%, height: 100%)[
          // Precipitation bars (from bottom) or "No precipitation" message
          #let total_precip = hourly_precip.sum()
          #if total_precip > 0 [
            #align(bottom)[
              #stack(dir: ltr, spacing: 0pt, ..hourly_precip
                .enumerate()
                .map(((i, p)) => {
                  let code = hourly_codes.at(i)
                  let fill = precip_fill(code)
                  // Scale: precip amount to percentage of chart height (max 80%)
                  let bar_pct = calc.min((p / precip_max) * 80, 80)
                  box(
                    width: bar_width,
                    height: bar_pct * 1%,
                    align(bottom)[
                      #rect(width: 75%, height: 100%, fill: fill)
                    ],
                  )
                }))
            ]
          ] else [
            #place(bottom + center, dy: -3em)[
              #text(size: 1.1em, fill: luma(120))[No precipitation]
            ]
          ]

          // Temperature line overlay using cetz
          #place(top + left)[
            #context {
              let chart_w = measure(box(width: 100%)).width
              let chart_h = measure(box(height: 100%)).height
              // Use fixed dimensions for the canvas
              let w = 710 // full width in pt
              let h = 120 // approximate height in pt

              canvas(length: 1pt, {
                // Draw temperature line
                // In cetz, y=0 is bottom, y increases upward
                let points = hourly_temps.enumerate().map(((i, t)) => {
                  let x = (i + 0.5) * (w / 24)
                  // Map temperature to y (higher temp = higher y = higher on chart)
                  let y_pct = (t - temp_min) / temp_range
                  let y = y_pct * h * 0.7 + h * 0.15 // 15% padding top/bottom for labels
                  (x, y)
                })

                // Draw the line connecting all points
                for i in range(points.len() - 1) {
                  let p1 = points.at(i)
                  let p2 = points.at(i + 1)
                  draw.line(p1, p2, stroke: 1.5pt + black)
                }

                // Draw small dots at each point
                for p in points {
                  draw.circle(p, radius: 2, fill: white, stroke: 1pt + black)
                }

                // Label the high point (above the line)
                let high_pt = points.at(temp_max_idx)
                draw.content(
                  (high_pt.at(0), high_pt.at(1) + 14),
                  text(size: 1.1em, weight: "bold")[#calc.round(temp_max)°],
                  anchor: "south",
                )

                // Label the low point (below the line)
                let low_pt = points.at(temp_min_idx)
                draw.content(
                  (low_pt.at(0), low_pt.at(1) - 14),
                  text(size: 1.1em, weight: "bold")[#calc.round(temp_min)°],
                  anchor: "north",
                )

                // "NOW" marker - vertical dashed line at current hour
                let now_x = (current_hour + 0.5) * (w / 24)
                draw.line(
                  (now_x, 0),
                  (now_x, h),
                  stroke: (paint: luma(100), thickness: 1pt, dash: "dashed"),
                )
                draw.content(
                  (now_x, h + 8),
                  text(size: 0.7em, weight: "medium", fill: luma(100))[NOW],
                  anchor: "south",
                )
              })
            }
          ]
        ]
      ]

      // X-axis labels (12-hour format)
      #v(0.25em)
      #let hour_labels = (
        (0, "12am"), (3, "3am"), (6, "6am"), (9, "9am"),
        (12, "12pm"), (15, "3pm"), (18, "6pm"), (21, "9pm"),
      )
      #stack(
          dir: ltr,
          spacing: 0pt,
          ..hour_labels.map(((h, label)) => {
            box(width: bar_width * 3, align(center)[
              #text(size: 0.7em)[#label]
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

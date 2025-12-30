#!/bin/sh
set -e

# Configuration
LAT="41.31"
LON="-72.92"
TIMEZONE="America/New_York"
OUTPUT_DIR="$(dirname "$0")"
DATA_FILE="$OUTPUT_DIR/weather_data.json"
NWS_FILE="$OUTPUT_DIR/nws_forecast.json"
OUTPUT_PNG="$OUTPUT_DIR/dashboard.png"
USER_AGENT="kindle-weather-dashboard (github.com/kljensen/kindle-weather-dashboard)"

# Fetch weather data from Open Meteo
# - current: temperature, weather code
# - hourly: precipitation probability (for bar graph)
# - daily: high/low temps, weather codes (for 7-day forecast)
echo "Fetching weather data from Open-Meteo..."
curl -s "https://api.open-meteo.com/v1/forecast?\
latitude=${LAT}&longitude=${LON}\
&current=temperature_2m,weather_code\
&hourly=precipitation_probability,temperature_2m,precipitation,weather_code\
&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset\
&temperature_unit=fahrenheit\
&timezone=${TIMEZONE}\
&forecast_days=8" > "$DATA_FILE"

# Fetch detailed text forecasts from NWS
echo "Fetching NWS text forecasts..."
# First, get the forecast office and grid coordinates
NWS_POINTS=$(curl -s -H "User-Agent: $USER_AGENT" \
  "https://api.weather.gov/points/${LAT},${LON}")

# Extract the forecast URL from the points response
FORECAST_URL=$(echo "$NWS_POINTS" | jq -r '.properties.forecast')

if [ "$FORECAST_URL" != "null" ] && [ -n "$FORECAST_URL" ]; then
  # Fetch the detailed forecast
  curl -s -H "User-Agent: $USER_AGENT" "$FORECAST_URL" > "$NWS_FILE"

  # Merge NWS forecast into the main data file
  # Extract the detailed forecasts array and add to weather_data.json
  jq -s '.[0] * {nws_forecast: .[1].properties.periods}' "$DATA_FILE" "$NWS_FILE" > "${DATA_FILE}.tmp"
  mv "${DATA_FILE}.tmp" "$DATA_FILE"
  rm -f "$NWS_FILE"
  echo "NWS forecasts merged."
else
  echo "Warning: Could not fetch NWS forecast URL"
fi

echo "Generating dashboard..."
typst compile "$OUTPUT_DIR/dashboard.typ" "$OUTPUT_PNG" --format png --ppi 150 --font-path "$OUTPUT_DIR/fonts"

echo "Done: $OUTPUT_PNG"

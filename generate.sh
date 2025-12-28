#!/bin/sh
set -e

# Configuration
LAT="41.31"
LON="-72.92"
TIMEZONE="America/New_York"
OUTPUT_DIR="$(dirname "$0")"
DATA_FILE="$OUTPUT_DIR/weather_data.json"
OUTPUT_PNG="$OUTPUT_DIR/dashboard.png"

# Fetch weather data from Open Meteo
# - current: temperature, weather code
# - hourly: precipitation probability (for bar graph)
# - daily: high/low temps, weather codes (for 7-day forecast)
echo "Fetching weather data..."
curl -s "https://api.open-meteo.com/v1/forecast?\
latitude=${LAT}&longitude=${LON}\
&current=temperature_2m,weather_code\
&hourly=precipitation_probability\
&daily=temperature_2m_max,temperature_2m_min,weather_code\
&temperature_unit=fahrenheit\
&timezone=${TIMEZONE}\
&forecast_days=8" > "$DATA_FILE"

echo "Generating dashboard..."
typst compile "$OUTPUT_DIR/dashboard.typ" "$OUTPUT_PNG" --format png --ppi 150

echo "Done: $OUTPUT_PNG"

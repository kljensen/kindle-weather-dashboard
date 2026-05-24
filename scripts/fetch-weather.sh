#!/bin/sh
set -eu

LAT="${WEATHER_LAT:-${LAT:-41.31}}"
LON="${WEATHER_LON:-${LON:--72.92}}"
TIMEZONE="${WEATHER_TIMEZONE:-${TIMEZONE:-America/New_York}}"
USER_AGENT="${WEATHER_USER_AGENT:-kindle-weather-dashboard (github.com/kljensen/kindle-weather-dashboard)}"

TMP_ROOT="${TMPDIR:-/tmp}"
TMP_DIR="$TMP_ROOT/kindle-weather-dashboard.$$"
DATA_FILE="$TMP_DIR/weather_data.json"
NWS_POINTS_FILE="$TMP_DIR/nws_points.json"
NWS_FILE="$TMP_DIR/nws_forecast.json"

mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

curl -fsS "https://api.open-meteo.com/v1/forecast?\
latitude=${LAT}&longitude=${LON}\
&current=temperature_2m,weather_code\
&hourly=precipitation_probability,temperature_2m,precipitation,weather_code\
&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset\
&temperature_unit=fahrenheit\
&timezone=${TIMEZONE}\
&forecast_days=8" > "$DATA_FILE"

FORECAST_URL=""
if curl -fsS -H "User-Agent: $USER_AGENT" \
    "https://api.weather.gov/points/${LAT},${LON}" > "$NWS_POINTS_FILE"; then
    FORECAST_URL="$(jq -r '.properties.forecast // empty' "$NWS_POINTS_FILE")"
fi

if [ -n "$FORECAST_URL" ]; then
    if curl -fsS -H "User-Agent: $USER_AGENT" "$FORECAST_URL" > "$NWS_FILE"; then
        jq -s '.[0] * {nws_forecast: (.[1].properties.periods // [])}' "$DATA_FILE" "$NWS_FILE"
        exit 0
    fi
fi

cat "$DATA_FILE"

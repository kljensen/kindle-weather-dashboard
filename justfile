# Kindle Weather Dashboard
set dotenv-load := true

mod devcontainer

# Default - show available commands
default:
    @just --list

# Generate the weather dashboard PNG
generate:
    ./generate.sh

# Start local HTTP server to serve the dashboard
serve port="8080":
    @echo "Serving dashboard at http://localhost:{{port}}/dashboard.png"
    @python3 -m http.server --directory . {{port}}

# Fetch weather data only (for debugging)
fetch:
    ./scripts/fetch-weather.sh | jq .

# Clean generated files
clean:
    rm -rf tmp/* output/* .typst-cache dashboard.png dashboard-*.png weather_data.json nws_forecast.json

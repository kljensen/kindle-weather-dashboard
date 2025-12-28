# Kindle Weather Dashboard
set dotenv-load := true

mod devcontainer

# Default - show available commands
default:
    @just --list

# Generate the weather dashboard PNG
generate:
    ./scripts/generate-dashboard.sh

# Start local HTTP server to serve the dashboard
serve port="8080":
    @echo "Serving dashboard at http://localhost:{{port}}/dashboard.png"
    @cd output && python3 -m http.server {{port}}

# Fetch weather data only (for debugging)
fetch:
    ./scripts/fetch-weather.sh | jq .

# Clean generated files
clean:
    rm -rf tmp/* output/*

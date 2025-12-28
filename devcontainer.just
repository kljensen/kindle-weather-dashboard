# Devcontainer management recipes

# List all devcontainer recipes
default:
    @just --list devcontainer

# Build the devcontainer
build:
    devcontainer build --workspace-folder .

# Rebuild the devcontainer from scratch (no cache)
rebuild: down
    devcontainer build --workspace-folder . --no-cache

# Start the devcontainer
up:
    devcontainer up --workspace-folder .

# Stop and remove the devcontainer
down:
    docker ps -a --filter "label=devcontainer.local_folder=$(pwd)" --format {{'{{.ID}}'}} | xargs -r docker rm -f

# Drop into a bash shell in the devcontainer
shell:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! devcontainer exec --workspace-folder . true 2>/dev/null; then
        echo "Container not running, starting..."
        devcontainer up --workspace-folder .
    fi
    devcontainer exec --workspace-folder . bash

# Run a command in the devcontainer
run CMD:
    devcontainer exec --workspace-folder . {{CMD}}

# Open VS Code in the devcontainer
code:
    code .

# Test the container tools
test:
    @echo "Testing container tools..."
    @devcontainer exec --workspace-folder . bash -c "\
        echo '=== Core Tools ===' && \
        echo 'curl:' && curl --version | head -1 && \
        echo 'jq:' && jq --version && \
        echo 'Typst:' && typst --version && \
        echo '' && \
        echo '=== AI Coding Assistants ===' && \
        echo 'Claude Code:' && (claude --version || echo 'installed') && \
        echo 'OpenAI Codex:' && (codex --version || echo 'installed') \
    "

# Show running devcontainers
ps:
    @docker ps --filter "label=devcontainer.local_folder" --format {{'table {{.Names}}\t{{.Status}}\t{{.Image}}'}}

# Clean up devcontainer images
clean:
    @docker images --filter "label=devcontainer.local_folder=$(pwd)" --format {{'{{.ID}}'}} | xargs -r docker rmi

# List credential volumes
volumes:
    @docker volume ls | grep kindle-weather

# Delete credential volumes
clean-volumes:
    @echo "This will delete your Claude credentials. Are you sure? (Ctrl-C to cancel)"
    @read -p "Press Enter to continue..."
    @docker volume rm kindle-weather-claude-credentials 2>/dev/null || true

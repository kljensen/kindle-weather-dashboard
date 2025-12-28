# Minimal Debian Bookworm-based Development Container for Kindle Weather Dashboard
# Base: Debian 12 (Bookworm) Slim - stable LTS with glibc compatibility
FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set default user and paths
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ==============================================================================
# SYSTEM ESSENTIALS
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    git \
    openssh-client \
    # SSH agent relay (for 1Password integration)
    socat \
    # Process tools (ps, top, etc.)
    procps \
    # User/group management
    sudo \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# DEVELOPMENT UTILITIES
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Text processing
    jq \
    less \
    # Search tools
    ripgrep \
    # File navigation
    tree \
    # Decompression (needed for binary installs below)
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI from official apt repository
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && gh --version

# Install Helix, Just, and yq in one layer
RUN HELIX_VERSION="25.01.1" \
    && JUST_VERSION="1.37.0" \
    && YQ_VERSION="v4.44.6" \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then \
        HELIX_ARCH="aarch64"; \
        JUST_ARCH="aarch64-unknown-linux-musl"; \
        YQ_ARCH="arm64"; \
    else \
        HELIX_ARCH="x86_64"; \
        JUST_ARCH="x86_64-unknown-linux-musl"; \
        YQ_ARCH="amd64"; \
    fi \
    # Helix
    && curl -fsSL "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-${HELIX_ARCH}-linux.tar.xz" -o helix.tar.xz \
    && tar -xJf helix.tar.xz \
    && mv helix-${HELIX_VERSION}-${HELIX_ARCH}-linux /usr/local/helix \
    && ln -s /usr/local/helix/hx /usr/local/bin/hx \
    && rm helix.tar.xz \
    # Just
    && curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz" -o just.tar.gz \
    && tar -xzf just.tar.gz \
    && mv just /usr/local/bin/just \
    && chmod +x /usr/local/bin/just \
    && rm just.tar.gz \
    # yq
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    # Verify installations
    && hx --version \
    && just --version \
    && yq --version

# ==============================================================================
# TYPST CLI
# ==============================================================================
RUN TYPST_VERSION="0.14.0" \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then \
        TYPST_ARCH="aarch64-unknown-linux-musl"; \
    else \
        TYPST_ARCH="x86_64-unknown-linux-musl"; \
    fi \
    && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_ARCH}.tar.xz" -o typst.tar.xz \
    && tar -xJf typst.tar.xz \
    && mv typst-${TYPST_ARCH}/typst /usr/local/bin/typst \
    && chmod +x /usr/local/bin/typst \
    && rm -rf typst.tar.xz typst-${TYPST_ARCH} \
    && typst --version

# Install fonts for Typst (DejaVu for good Unicode coverage)
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# DELIBERATE THINKING MCP SERVER
# ==============================================================================
RUN DELIBERATE_VERSION="v0.2.0" \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then \
        DELIBERATE_ARCH="aarch64-unknown-linux-musl"; \
    else \
        DELIBERATE_ARCH="x86_64-unknown-linux-musl"; \
    fi \
    && curl -fsSL "https://github.com/kljensen/deliberate-thinking/releases/download/${DELIBERATE_VERSION}/deliberate-thinking-rust-${DELIBERATE_ARCH}.tar.xz" -o deliberate.tar.xz \
    && tar -xJf deliberate.tar.xz \
    && mv deliberate-thinking-rust-${DELIBERATE_ARCH}/deliberate-thinking-server /usr/local/bin/ \
    && chmod +x /usr/local/bin/deliberate-thinking-server \
    && rm -rf deliberate.tar.xz deliberate-thinking-rust-${DELIBERATE_ARCH} \
    && deliberate-thinking-server --help || echo "Deliberate thinking server installed"

# ==============================================================================
# NODE.JS & AI TOOLS
# ==============================================================================
# Node.js 22.x (required for AI CLI tools)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify Node.js installation
RUN node --version && npm --version

# Install AI coding assistant CLIs globally
RUN npm install -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    @google/gemini-cli \
    && npm cache clean --force \
    && claude --version || echo "Claude Code installed" \
    && codex --version || echo "Codex installed" \
    && gemini --version || echo "Gemini CLI installed"

# ==============================================================================
# USER SETUP
# ==============================================================================
# Create non-root user with sudo access (matches VS Code expectations)
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ==============================================================================
# WORKSPACE SETUP
# ==============================================================================
WORKDIR /workspace

# Switch to non-root user
USER $USERNAME

# Default shell
CMD ["/bin/bash"]

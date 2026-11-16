ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Everything the terminal needs is baked into the image so startup never
# depends on the network. Debian trixie ships Python 3.13, which both
# Mistral Vibe (>= 3.12) and ha-mcp (3.13) run on, so no Python download is
# needed at runtime.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        less \
        nano \
        nginx \
        procps \
        python3 \
        python3-pip \
        python3-requests \
        python3-tomlkit \
        python3-venv \
        python3-yaml \
        tmux \
        tree \
        ttyd \
        vim \
        wget \
    && rm -rf /var/lib/apt/lists/*

# uv runs ha-mcp (uvx) and installs/updates Mistral Vibe
RUN pip3 install --no-cache-dir --break-system-packages uv==0.11.28

# Bundled Mistral Vibe, frozen at image build time. With vibe_auto_update
# enabled, run.sh keeps a persistent, updated copy in /data that takes
# precedence on PATH.
ARG VIBE_VERSION=3.1.2
RUN UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin \
        uv tool install --no-cache --python /usr/bin/python3 "mistral-vibe==${VIBE_VERSION}" \
    && vibe --version

# Without a desktop session there is no keyring service. Force Vibe's
# documented fallback so the key from "Sign in with Mistral" is always stored
# in $VIBE_HOME/.env, which lives in /data and survives restarts.
ENV PYTHON_KEYRING_BACKEND=keyring.backends.fail.Keyring

WORKDIR /config

COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh /opt/scripts/*.sh

# ttyd's own page plus ttyd-extras.js (OSC 52 clipboard + Shift+Enter),
# built once from this image's ttyd. If Debian's ttyd page ever changes
# shape, the build continues and run.sh serves ttyd's stock page instead
# (copy then needs Shift+drag, Shift+Enter needs Ctrl+J).
RUN /opt/scripts/build-ttyd-index.sh /opt/ttyd/index.html \
    || echo "WARNING: patched ttyd page not built; stock page will be used"

CMD ["/run.sh"]

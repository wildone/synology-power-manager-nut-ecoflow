# syntax=docker/dockerfile:1

FROM debian:12-slim

ARG PKGSCRIPTS_VERSION="main"
ENV DSM_VERSION="7.2" \
    DSM_PLATFORM="apollolake" \
    TOOLKIT_ROOT="/toolkit" \
    WORKSPACE="/workspace"

# Install base dependencies required by Synology pkgscripts toolkit.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        cifs-utils \
        curl \
        git \
        jq \
        make \
        python-is-python3 \
        python3 \
        python3-pip \
        unzip \
        vim \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Prepare toolkit directories and fetch pkgscripts.
RUN mkdir -p "$TOOLKIT_ROOT" "$WORKSPACE" && \
    git clone --branch "$PKGSCRIPTS_VERSION" https://github.com/SynologyOpenSource/pkgscripts-ng "$TOOLKIT_ROOT/pkgscripts-ng"

WORKDIR $TOOLKIT_ROOT/pkgscripts-ng

# Copy helper entrypoint script.
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["$TOOLKIT_ROOT", "$WORKSPACE"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

FROM netbirdio/netbird:latest@sha256:ef63d54be353aca75f13d920632151002d5f841c49a4eb29a8535aeb11ce3736
# Build arguments:
#   - TARGETARCH: The target architecture (e.g., amd64, arm64). This is automatically provided by docker/build-push-action.
#   - COREDNS_VERSION_TAG: The git tag for the CoreDNS release (e.g., v1.11.1).
#   - COREDNS_VERSION_NUM: The version number for the CoreDNS release (e.g., 1.11.1).

ARG COREDNS_VERSION_TAG
ARG COREDNS_VERSION_NUM

RUN \
    # 1. Install temporary dependencies for downloading and extracting using apk.
    # --no-cache is a best practice for Alpine to keep image layers small.
    apk add --no-cache curl tar && \
    # 2. Determine architecture
    _arch=$(uname -m) && \
    case "$_arch" in \
        x86_64) _target_arch="amd64" ;; \
        aarch64) _target_arch="arm64" ;; \
        *) echo "Unsupported architecture: $_arch" >&2; exit 1 ;; \
    esac && \
    \
    # 3. Log the versions we are building for clarity.
    echo "Building with CoreDNS version tag: ${COREDNS_VERSION_TAG}" && \
    echo "Target architecture: ${_target_arch}" && \
    # 4. Check if build arguments are provided.
    if [ -z "${COREDNS_VERSION_TAG}" ] || [ -z "${COREDNS_VERSION_NUM}" ]; then \
      echo "Error: COREDNS_VERSION_TAG and COREDNS_VERSION_NUM build arguments must be set." >&2; \
      exit 1; \
    fi && \
    # 5. Download the correct CoreDNS binary based on the arguments.
    curl -L -o coredns.tgz "https://github.com/coredns/coredns/releases/download/${COREDNS_VERSION_TAG}/coredns_${COREDNS_VERSION_NUM}_linux_${_target_arch}.tgz" && \
    # 6. Extract the binary and move it to a directory in the PATH.
    tar -xzf coredns.tgz && \
    mv coredns /usr/local/bin/coredns && \
    # 7. Clean up: remove the archive and the temporary dependencies.
    rm coredns.tgz && \
    apk del curl tar

COPY Corefile /etc/coredns/Corefile

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /etc/coredns

ENTRYPOINT ["/entrypoint.sh"]

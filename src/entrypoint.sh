#!/bin/bash

SOCI_USER="awslabs"
SOCI_REPO="soci-snapshotter"

REQUIRED_ENV_VARS=("REGISTRY" "REGISTRY_PASSWORD" "REPO_NAME" "REPOSITORY_TAG")

set -e

shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
    alias info_log="echo -e \"\033[1;32mINFO\033[0m:\""
    alias error_log="echo -e \"\033[1;31mERROR\033[0m:\""
else
    alias info_log="echo \"INFO:\""
    alias error_log="echo \"ERROR:\""
fi

RESPONSE=$(curl -s "https://api.github.com/repos/${SOCI_USER}/${SOCI_REPO}/releases/latest")

LATEST_VERSION=$(echo "$RESPONSE" | jq -r '.tag_name')

case "$RUNNER_OS" in
    Linux)
    case "$RUNNER_ARCH" in
        X64)
            wget --no-verbose https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz
            wget --no-verbose https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-amd64.tar.gz && cp ./soci /usr/local/bin && cp ./${SOCI_REPO}-grpc /usr/local/bin
            ;;
        ARM64)
            wget --no-verbose https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz
            wget --no-verbose https://github.com/${SOCI_USER}/${SOCI_REPO}/releases/download/${LATEST_VERSION}/${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum
            sha256sum -c  ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz.sha256sum;
            tar -xvf ${SOCI_REPO}-$(echo "$LATEST_VERSION" | sed 's/^v//')-linux-arm64.tar.gz && cp ./soci /usr/local/bin && cp ./${SOCI_REPO}-grpc /usr/local/bin
            ;;
        *)
            error_log "unsupported architecture $RUNNER_ARCH"
            exit 1
            ;;
    esac
    ;;
    *)
        error_log "unsupported OS $RUNNER_OS"
        error_log "Only Linux binaries are available"
        exit 1
        ;;
esac

SUDO=
if command -v sudo >/dev/null; then
    SUDO=sudo
    info_log "Sudo functional. Starting system installation"
elif [ "$EUID" -eq 0 ]; then
    info_log "Root permissions. Starting system installation"
else
    info_log "Sudo not functional and not root. continue with user permissions"
fi

rm index.sh THIRD_PARTY_LICENSES NOTICE.md ${SOCI_REPO}-grpc

check_empty() {
    if [ -z "${!1}" ]; then
        info_log "Info: $1 is empty. Exiting."
        break
    else
        info_log "All required environment variables are set."

        info_log "Pulling Docker image using CTR"
        sudo ctr i pull --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG

        info_log "Creating SOCI index for Docker image using SOCI"
        sudo soci create $REGISTRY/$REPO_NAME:$REPOSITORY_TAG

        info_log "Pushing SOCI Docker image using SOCI"
        sudo soci push --user $REGISTRY_USER:$REGISTRY_PASSWORD $REGISTRY/$REPO_NAME:$REPOSITORY_TAG
    fi
}

for var in "${REQUIRED_ENV_VARS[@]}"; do
    check_empty "$var"
done

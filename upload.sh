#!/bin/bash
set -e  # Exit on any error

echo "Build and Push jasonacox/grafana to Docker Hub"
echo ""

# Check if docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: docker buildx is not available. Please install Docker Desktop or enable buildx."
    exit 1
fi

# Determine version of grafana from package.json
VER=$(grep '"version":' package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')

if [ -z "$VER" ]; then
    echo "Error: Could not determine version from package.json"
    exit 1
fi

echo "Detected Grafana version: ${VER}"
echo "Git commit: $(git rev-parse --short HEAD)"
echo ""

# Check with user before proceeding
echo "Build and push jasonacox/grafana:${VER} to Docker Hub?"
read -p "Press [Enter] to continue or Ctrl-C to cancel..."

# Build jasonacox/grafana:x.y.z
echo "* BUILD jasonacox/grafana:${VER}"
docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --build-arg BUILD_BRANCH=v${VER} \
  --build-arg COMMIT_SHA=$(git rev-parse HEAD) \
  --label org.opencontainers.image.version=${VER} \
  --label org.opencontainers.image.source=https://github.com/jasonacox/grafana \
  --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
  --push -t jasonacox/grafana:${VER} .
echo ""

# Build jasonacox/grafana:latest
echo "* BUILD jasonacox/grafana:latest"
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --build-arg BUILD_BRANCH=v${VER} \
  --build-arg COMMIT_SHA=$(git rev-parse HEAD) \
  --label org.opencontainers.image.version=${VER} \
  --label org.opencontainers.image.source=https://github.com/jasonacox/grafana \
  --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
  --push -t jasonacox/grafana:latest .
echo ""

# Verify
echo "* VERIFY jasonacox/grafana:${VER}"
docker buildx imagetools inspect jasonacox/grafana:${VER} | grep Platform
echo ""
echo "* VERIFY jasonacox/grafana:latest"
docker buildx imagetools inspect jasonacox/grafana | grep Platform
echo ""

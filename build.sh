#!/bin/bash
set -e  # Exit on any error

echo "Build jasonacox/grafana for multiple platforms (no upload)"
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
echo "Build jasonacox/grafana:${VER} for all platforms (local build only)?"
read -p "Press [Enter] to continue or Ctrl-C to cancel..."

# Build jasonacox/grafana:x.y.z for all platforms
echo "* BUILD jasonacox/grafana:${VER}"
docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --build-arg BUILD_BRANCH=v${VER} \
  --build-arg COMMIT_SHA=$(git rev-parse HEAD) \
  --label org.opencontainers.image.version=${VER} \
  --label org.opencontainers.image.source=https://github.com/jasonacox/grafana \
  --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
  --output type=image,push=false \
  -t jasonacox/grafana:${VER} .
echo ""

# Ask if user wants to build latest tag as well
echo "Build jasonacox/grafana:latest as well?"
read -p "Press [Enter] to build latest or 's' to skip: " build_latest

if [ "$build_latest" != "s" ]; then
  # Build jasonacox/grafana:latest (multi-platform)
  echo "* BUILD jasonacox/grafana:latest (multi-platform)"
  docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --build-arg BUILD_BRANCH=v${VER} \
    --build-arg COMMIT_SHA=$(git rev-parse HEAD) \
    --label org.opencontainers.image.version=${VER} \
    --label org.opencontainers.image.source=https://github.com/jasonacox/grafana \
    --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
    --output type=image,push=false \
    -t jasonacox/grafana:latest .
  echo ""
else
  echo "Skipping latest tag build."
  echo ""
fi

echo "Build completed successfully!"
echo "Images built for platforms: linux/amd64, linux/arm64, linux/arm/v7"
echo ""
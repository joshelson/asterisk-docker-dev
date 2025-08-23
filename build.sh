#!/bin/bash

# Asterisk Docker Development Environment - Build Script
# Enhanced build script with options for different build types

set -e

IMAGE_NAME="asterisk-dev-container"
BUILD_ARGS=""
TAG="latest"
PROGRESS="auto"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🛠️  Asterisk Docker Build Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tag TAG          Set image tag (default: latest)"
    echo "  -p, --progress TYPE    Set progress output: auto, plain, tty (default: auto)"
    echo "  --no-cache            Build without using cache"
    echo "  --debug               Build with debug information"
    echo "  --lua-version VER     Override Lua version"
    echo "  --sipp-version VER    Override SIPp version"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Standard build"
    echo "  $0 --tag v2.0                   # Build with custom tag"
    echo "  $0 --progress plain             # Build with detailed output"
    echo "  $0 --no-cache --debug           # Clean debug build"
    echo "  $0 --lua-version 5.4.6          # Override Lua version"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--progress)
            PROGRESS="$2"
            shift 2
            ;;
        --no-cache)
            BUILD_ARGS="$BUILD_ARGS --no-cache"
            shift
            ;;
        --debug)
            BUILD_ARGS="$BUILD_ARGS --build-arg BUILD_TYPE=debug"
            shift
            ;;
        --lua-version)
            BUILD_ARGS="$BUILD_ARGS --build-arg LUA_VERSION=$2"
            shift 2
            ;;
        --sipp-version)
            BUILD_ARGS="$BUILD_ARGS --build-arg SIPP_VERSION=$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🏗️  Building Asterisk Development Container${NC}"
echo -e "${YELLOW}📦 Image: ${IMAGE_NAME}:${TAG}${NC}"
echo -e "${YELLOW}⚙️  Build Args: ${BUILD_ARGS}${NC}"
echo ""

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile not found in current directory${NC}"
    exit 1
fi

# Start build
echo -e "${YELLOW}🚀 Starting build...${NC}"
start_time=$(date +%s)

docker build \
    --progress="$PROGRESS" \
    --tag "${IMAGE_NAME}:${TAG}" \
    $BUILD_ARGS \
    .

end_time=$(date +%s)
build_duration=$((end_time - start_time))

echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo -e "${GREEN}⏱️  Build time: ${build_duration} seconds${NC}"
echo -e "${GREEN}🏷️  Tagged as: ${IMAGE_NAME}:${TAG}${NC}"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo -e "   Run container: ${YELLOW}./restart-docker.sh${NC}"
echo -e "   Or manually:   ${YELLOW}docker run -it --rm ${IMAGE_NAME}:${TAG}${NC}"

#!/bin/bash

# Asterisk Docker Development Environment - Restart Script
# Quickly stops, removes, and restarts the Asterisk development container

set -e

CONTAINER_NAME="asterisk-dev"
IMAGE_NAME="asterisk-dev-container"
DEFAULT_ASTERISK_PATH="$HOME/dev/asterisk"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Restarting Asterisk Development Container...${NC}"

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}📦 Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Removing existing container...${NC}"
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Check if Asterisk source directory exists
ASTERISK_PATH="${1:-$DEFAULT_ASTERISK_PATH}"
if [ ! -d "$ASTERISK_PATH" ]; then
    echo -e "${RED}❌ Asterisk source directory not found: $ASTERISK_PATH${NC}"
    echo -e "${YELLOW}💡 Usage: $0 [asterisk-source-path]${NC}"
    echo -e "${YELLOW}   Example: $0 /Users/josh/dev/gogo/asterisk${NC}"
    exit 1
fi

echo -e "${GREEN}📁 Using Asterisk source: $ASTERISK_PATH${NC}"

# Start new container
echo -e "${YELLOW}🚀 Starting new container...${NC}"
docker run -it --rm --name ${CONTAINER_NAME} \
    -p 5060:5060/udp -p 5060:5060/tcp \
    -p 5038:5038/tcp \
    -p 10000-10100:10000-10100/udp \
    -h asterisk-dev-container \
    -v "$ASTERISK_PATH":/usr/src/asterisk \
    -v "$HOME/.bash_history":/root/.bash_history \
    --entrypoint /bin/bash ${IMAGE_NAME}

echo -e "${GREEN}✅ Container restarted successfully!${NC}"

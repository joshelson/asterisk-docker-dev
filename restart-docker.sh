#!/bin/bash

# Asterisk Docker Development Environment - Restart Script
# Quickly stops, removes, and restarts the Asterisk development container

set -e

CONTAINER_NAME="asterisk-dev"
IMAGE_NAME="asterisk-dev-container"
DEFAULT_ASTERISK_PATH="$HOME/dev/asterisk"
PERSISTENT_MODE=false
FORCE_KILL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🐳 Asterisk Docker Restart Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] [asterisk-source-path]"
    echo ""
    echo "Options:"
    echo "  -p, --persistent      Run container in persistent mode (detached)"
    echo "  -i, --interactive     Run container in interactive mode (default)"
    echo "  -f, --force          Force kill conflicting containers/processes"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode with default path"
    echo "  $0 /path/to/asterisk                 # Interactive mode with custom path"
    echo "  $0 --persistent                      # Persistent mode with default path"
    echo "  $0 --persistent /path/to/asterisk    # Persistent mode with custom path"
    echo "  $0 --force --persistent              # Force kill conflicts, then start persistent"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--persistent)
            PERSISTENT_MODE=true
            shift
            ;;
        -i|--interactive)
            PERSISTENT_MODE=false
            shift
            ;;
        -f|--force)
            FORCE_KILL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            DEFAULT_ASTERISK_PATH="$1"
            shift
            ;;
    esac
done

if [ "$PERSISTENT_MODE" = true ]; then
    echo -e "${YELLOW}🔄 Restarting Asterisk Development Container (Persistent Mode)...${NC}"
else
    echo -e "${YELLOW}🔄 Restarting Asterisk Development Container (Interactive Mode)...${NC}"
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}📦 Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Removing existing container...${NC}"
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Check for port conflicts
check_port_conflict() {
    local port=$1
    local protocol=${2:-tcp}
    
    if command -v lsof >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port -s$protocol:listen 2>/dev/null)
        if [ ! -z "$pid" ]; then
            echo -e "${RED}⚠️  Port $port is already in use by process $pid${NC}"
            echo -e "${YELLOW}💡 Run: sudo lsof -i :$port to see what's using it${NC}"
            echo -e "${YELLOW}💡 Or try: docker stop \$(docker ps -q --filter \"publish=$port\")${NC}"
            return 1
        fi
    fi
    return 0
}

# Handle port conflicts
handle_port_conflicts() {
    echo -e "${YELLOW}🔍 Checking for port conflicts...${NC}"
    
    local conflicts=false
    local ports_to_check=("5060" "5038")
    
    for port in "${ports_to_check[@]}"; do
        if command -v lsof >/dev/null 2>&1; then
            local pids=$(lsof -ti:$port 2>/dev/null)
            if [ ! -z "$pids" ]; then
                conflicts=true
                echo -e "${RED}⚠️  Port $port is in use by process(es): $pids${NC}"
                
                if [ "$FORCE_KILL" = true ]; then
                    echo -e "${YELLOW}🔨 Force killing processes using port $port...${NC}"
                    
                    # First try to stop Docker containers using this port
                    local docker_containers=$(docker ps -q --filter "publish=$port" 2>/dev/null)
                    if [ ! -z "$docker_containers" ]; then
                        echo -e "${YELLOW}📦 Stopping Docker containers using port $port...${NC}"
                        docker stop $docker_containers 2>/dev/null || true
                        sleep 2
                    fi
                    
                    # Then kill any remaining processes
                    local remaining_pids=$(lsof -ti:$port 2>/dev/null)
                    if [ ! -z "$remaining_pids" ]; then
                        echo -e "${YELLOW}💀 Killing remaining processes: $remaining_pids${NC}"
                        sudo kill -9 $remaining_pids 2>/dev/null || true
                        sleep 1
                    fi
                    
                    # Verify port is now free
                    local final_check=$(lsof -ti:$port 2>/dev/null)
                    if [ ! -z "$final_check" ]; then
                        echo -e "${RED}❌ Failed to free port $port${NC}"
                        exit 1
                    else
                        echo -e "${GREEN}✅ Port $port is now available${NC}"
                    fi
                fi
            fi
        fi
    done
    
    if [ "$conflicts" = true ] && [ "$FORCE_KILL" = false ]; then
        echo -e "${RED}❌ Port conflicts detected. Use --force to automatically resolve them.${NC}"
        echo -e "${YELLOW}💡 Manual resolution options:${NC}"
        echo -e "${YELLOW}   sudo lsof -i :5060${NC}"
        echo -e "${YELLOW}   docker stop \$(docker ps -q --filter \"publish=5060\")${NC}"
        echo -e "${YELLOW}   Or run with: $0 --force${NC}"
        exit 1
    fi
}

handle_port_conflicts

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

if [ "$PERSISTENT_MODE" = true ]; then
    # Persistent mode - container runs in background
    docker run -d --name ${CONTAINER_NAME} \
        -p 5060:5060/udp -p 5060:5060/tcp \
        -p 5038:5038/tcp \
        -p 10000-10100:10000-10100/udp \
        -h asterisk-dev-container \
        -v "$ASTERISK_PATH":/usr/src/asterisk \
        -v "$HOME/.bash_history":/root/.bash_history \
        --entrypoint tail ${IMAGE_NAME} -f /dev/null
    
    echo -e "${GREEN}✅ Container started in persistent mode!${NC}"
    echo -e "${BLUE}💡 To enter the container: ${YELLOW}docker exec -it ${CONTAINER_NAME} /bin/bash${NC}"
    echo -e "${BLUE}💡 To stop the container: ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
else
    # Interactive mode - container exits when shell exits
    docker run -it --rm --name ${CONTAINER_NAME} \
        -p 5060:5060/udp -p 5060:5060/tcp \
        -p 5038:5038/tcp \
        -p 10000-10100:10000-10100/udp \
        -h asterisk-dev-container \
        -v "$ASTERISK_PATH":/usr/src/asterisk \
        -v "$HOME/.bash_history":/root/.bash_history \
        --entrypoint /bin/bash ${IMAGE_NAME}
    
    echo -e "${GREEN}✅ Container session ended!${NC}"
fi

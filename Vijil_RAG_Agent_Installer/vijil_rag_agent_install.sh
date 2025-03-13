#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Vijil RAG Agent Setup Script ===${NC}"
echo "Setting up Ollama (Local), Docker, and Vijil RAG Agent..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker Desktop is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker Desktop not found. Installing...${NC}"
    # Download the latest Docker.dmg
    curl -o Docker.dmg https://desktop.docker.com/mac/main/arm64/Docker.dmg
    
    # Mount the DMG
    hdiutil attach Docker.dmg
    
    # Copy the app to Applications folder
    cp -R "/Volumes/Docker/Docker.app" /Applications/
    
    # Unmount the DMG
    hdiutil detach "/Volumes/Docker"
    
    # Clean up
    rm Docker.dmg
    
    echo -e "${GREEN}Docker Desktop installed. Please start Docker Desktop and then run this script again.${NC}"
    echo "After Docker Desktop is running, run this script again."
    open "/Applications/Docker.app"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running and will be started. Please run the installer again.${NC}"
    open "/Applications/Docker.app"
    exit 1
fi

echo -e "${GREEN}Docker is running.${NC}"

# Install Ollama if not installed
if ! command_exists ollama; then
    echo -e "Ollama is not installed on this machine. Please uninstall manually by visiting https://ollama.com/download/mac"
    exit 1
fi

# Ensure Ollama is running
if ! pgrep -f "ollama" >/dev/null; then
    echo -e "${BLUE}Starting Ollama...${NC}"
    nohup ollama serve >/dev/null 2>&1 &
    sleep 5
else
    echo -e "${GREEN}Ollama is already running${NC}"
fi

# Stop and remove existing containers
for container in vijil-rag-agent; do
    if docker ps -a | grep -q $container; then
        echo "Stopping and removing existing $container..."
        docker stop $container
        docker rm $container
    fi
done

sleep 10

find_available_port() {
    local port=8000
    local max_port=9000  # Prevent infinite loop by setting a max limit

    while netstat -an | grep -q ":$port .*LISTEN"; do
        echo "Port ${port} is in use, trying next port..." >&2
        port=$((port + 1))

        if [ "$port" -gt "$max_port" ]; then
            echo "No available ports found in range 8000-$max_port." >&2
            return 1  # Indicate failure instead of exiting
        fi
    done

    echo "$port"  # Ensure the port is printed
}

# DEBUG: Capture the function output
UI_PORT=$(find_available_port)

# Check if function succeeded
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Using port ${UI_PORT} for Vijil RAG Agent${NC}"
else
    echo -e "${RED}Failed to find an available port.${NC}"
    exit 1
fi

MODEL_NAME="llama3.2:1b"
# Get the number of installed models, ignoring the header line
MODEL_COUNT=$(ollama list | tail -n +2 | wc -l)

# Check if any Ollama model is installed
if [ "$MODEL_COUNT" -gt 0 ]; then
    echo -e "${GREEN}At least one Ollama model is already installed.${NC}"
else
    echo -e "${BLUE}No Ollama models found. Pulling default model: $MODEL_NAME...${NC}"
    ollama pull "$MODEL_NAME"

    # Verify if the model was pulled successfully
    if ollama list | grep -q "$MODEL_NAME"; then
        echo -e "${GREEN}Model $MODEL_NAME installed successfully.${NC}"
    else
        echo -e "${RED}Failed to install model: $MODEL_NAME. Please try manually.${NC}"
        exit 1
    fi
fi

# Create the Docker network if it doesn't exist
if ! docker network inspect ollama-docker &> /dev/null; then
    echo "Creating docker network 'ollama-docker'..."
    docker network create ollama-docker
    echo -e "${GREEN}Network created.${NC}"
else
    echo -e "${GREEN}Network 'ollama-docker' already exists.${NC}"
fi


# echo "Starting Transformers Inference API..."
# docker run -d --name t2v-transformers \
#     --network ollama-docker \
#     -p 8081:8080 \
#     cr.weaviate.io/semitechnologies/transformers-inference:sentence-transformers-all-MiniLM-L6-v2

# **Run Weaviate**
# echo "Starting Weaviate..."
# docker run -d --name weaviate \
#     --network ollama-docker \
#     -p 8080:8080 \
#     -v weaviate_data:/var/lib/weaviate \
#     --restart on-failure:0 \
#     -e QUERY_DEFAULTS_LIMIT=25 \
#     -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
#     -e PERSISTENCE_DATA_PATH="/var/lib/weaviate" \
#     -e ENABLE_MODULES="text2vec-transformers" \
#     -e TRANSFORMERS_INFERENCE_API="http://t2v-transformers:8080" \
#     semitechnologies/weaviate:1.25.10

# **Run Vijil RAG Agent**
echo "Starting Vijil RAG Agent..."
docker run -d --name vijil-rag-agent \
    --network ollama-docker \
    -p ${UI_PORT}:8000 \
    -v ./data:/data \
    -e OLLAMA_URL="http://host.docker.internal:11434" \
    -e OLLAMA_MODEL=$MODEL_NAME \
    -e DEFAULT_DEPLOYMENT="Local" \
    --restart always \
    ansharora23/verba-vijil:mac

# **Check running services**
echo -e "${BLUE}Checking if services are running...${NC}"

for service in vijil-rag-agent; do
    if docker ps | grep -q "$service"; then
        echo -e "${GREEN}✓ $service is running${NC}"
    else
        echo -e "${RED}✗ $service failed to start${NC}"
    fi
done

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}Vijil RAG Agent will available at: http://localhost:${UI_PORT}${NC} in 15 seconds"
# echo -e "${BLUE}Weaviate is available at: http://localhost:8080${NC}"

sleep 15

# Open browser
echo "Opening browser..."
open "http://localhost:${UI_PORT}"

echo -e "${BLUE}=== Additional Information ===${NC}"
echo "- To stop the services: docker stop weaviate vijil-rag-agent"
echo "- To start the services: docker start weaviate vijil-rag-agent"
# echo "- Vijil RAG Agent data is stored in the 'weaviate_data' Docker volume"
echo "- Vijil is running on port: ${UI_PORT}"
#!/bin/bash

# Define colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

### Step 1: Install Homebrew if not installed
if ! command_exists brew; then
    echo -e "${RED}Homebrew is not installed. Installing Homebrew...${NC}"
    
    # Download and install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Verify installation
    if ! command_exists brew; then
        echo -e "${RED}Failed to install Homebrew. Please install manually from https://brew.sh/${NC}"
        exit 1
    fi

    echo -e "${GREEN}Homebrew installed successfully.${NC}"

    # Ensure Homebrew is available in the current shell session
    eval "$(/opt/homebrew/bin/brew shellenv)" # Apple Silicon (M1/M2/M3)
    eval "$(/usr/local/bin/brew shellenv)"    # Intel Macs
else
    echo -e "${GREEN}Homebrew is already installed.${NC}"
fi

### Step 2: Install Ollama if not installed
if ! command_exists ollama; then
    echo -e "${BLUE}Installing Ollama...${NC}"

    brew install ollama

    # Verify installation
    if command_exists ollama; then
        echo -e "${GREEN}Ollama installed successfully.${NC}"
    else
        echo -e "${RED}Failed to install Ollama. Please install manually from https://ollama.com${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Ollama is already installed.${NC}"
fi

### Step 3: Ensure Ollama is running
if ! pgrep -f "ollama" >/dev/null; then
    echo -e "${BLUE}Starting Ollama...${NC}"
    nohup ollama serve >/dev/null 2>&1 &
    sleep 5
fi

echo -e "${GREEN}Ollama is ready to use.${NC}"

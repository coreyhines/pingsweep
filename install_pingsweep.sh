#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to the .zshrc file
ZSHRC="$HOME/.zshrc"

# Check if .zshrc exists
if [ ! -f "$ZSHRC" ]; then
    echo -e "${YELLOW}Warning: $ZSHRC does not exist.${NC}"
    echo -e "Creating $ZSHRC file..."
    touch "$ZSHRC"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Unable to create $ZSHRC. Check permissions.${NC}"
        exit 1
    fi
fi

# Check if pingsweep function is already defined in .zshrc
if grep -q "pingsweep()" "$ZSHRC"; then
    echo -e "${YELLOW}The pingsweep function is already defined in your $ZSHRC.${NC}"
    echo -e "If you wish to update it, you can remove the existing function and run this script again."
    exit 0
fi

# Get the full path to the pingsweep script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PINGSWEEP_PATH="$SCRIPT_DIR/pingsweep"

# Make sure pingsweep exists
if [ ! -f "$PINGSWEEP_PATH" ]; then
    echo -e "${RED}Error: pingsweep script not found at $PINGSWEEP_PATH${NC}"
    exit 1
fi

# Add separator to .zshrc
echo -e "\n# Added by pingsweep installer $(date)" >> "$ZSHRC"

# Append pingsweep function to .zshrc
cat "$PINGSWEEP_PATH" >> "$ZSHRC"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully added pingsweep function to $ZSHRC!${NC}"
    echo -e "To start using it, either:"
    echo -e "  1. Restart your terminal"
    echo -e "  2. Run: ${YELLOW}source $ZSHRC${NC}"
    exit 0
else
    echo -e "${RED}Error: Failed to append pingsweep function to $ZSHRC.${NC}"
    echo -e "Check file permissions or try manual installation."
    exit 1
fi 

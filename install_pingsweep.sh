#!/bin/bash
#set -x

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to the .zshrc file
ZSHRC="$HOME/.zshrc"

# Get the full path to the pingsweep script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PINGSWEEP_PATH="$SCRIPT_DIR/pingsweep"

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
    # Extract current pingsweep() from .zshrc
    awk '/^pingsweep\(\)/ {in_func=1; brace=0} in_func {brace+=gsub(/{/,"{"); brace-=gsub(/}/,"}"); print; if (brace<=0 && /}/) {in_func=0}}' "$ZSHRC" > /tmp/current_pingsweep_func
    # Extract new pingsweep() from script
    awk '/^pingsweep\(\)/ {in_func=1; brace=0} in_func {brace+=gsub(/{/,"{"); brace-=gsub(/}/,"}"); print; if (brace<=0 && /}/) {in_func=0}}' "$PINGSWEEP_PATH" > /tmp/new_pingsweep_func
    if cmp -s /tmp/current_pingsweep_func /tmp/new_pingsweep_func; then
        echo -e "${YELLOW}pingsweep() in $ZSHRC is already up to date.${NC}"
        rm -f /tmp/current_pingsweep_func /tmp/new_pingsweep_func
        exit 0
    else
        echo -e "${YELLOW}A different version of pingsweep() is available.${NC}"
        diff -u /tmp/current_pingsweep_func /tmp/new_pingsweep_func || true
        read -r -p "Do you want to replace the current pingsweep() in $ZSHRC? [Y/n] " answer
        answer=${answer:-Y}
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            # Remove old pingsweep() from .zshrc
            awk '
            /^pingsweep\(\)/ {in_func=1; brace=0}
            in_func {
              brace += gsub(/{/, "{")
              brace -= gsub(/}/, "}")
              if (brace <= 0 && /}/) {in_func=0; next}
              next
            }
            {print}
            ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
            # Add separator and new function
            echo -e "\n# Added by pingsweep installer $(date)" >> "$ZSHRC"
            cat "$PINGSWEEP_PATH" >> "$ZSHRC"
            echo -e "${GREEN}Successfully updated pingsweep function in $ZSHRC!${NC}"
            echo -e "To start using it, either:"
            echo -e "  1. Restart your terminal"
            echo -e "  2. Run: ${YELLOW}source $ZSHRC${NC}"
            rm -f /tmp/current_pingsweep_func /tmp/new_pingsweep_func
            exit 0
        else
            echo -e "${YELLOW}Update cancelled. No changes made.${NC}"
            rm -f /tmp/current_pingsweep_func /tmp/new_pingsweep_func
            exit 0
        fi
    fi
fi

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

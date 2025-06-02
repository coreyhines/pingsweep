#!/bin/bash
#set -x

# Installer will use ~/dotfiles/zshrc if it exists, otherwise fallback to ~/.zshrc
if [ -f "$HOME/dotfiles/zshrc" ]; then
    ZSHRC="$HOME/dotfiles/zshrc"
    DOTFILES_USED=1
else
    ZSHRC="$HOME/.zshrc"
    DOTFILES_USED=0
fi

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to the .zshfunc file
ZSHFUNC="$HOME/.zshfunc"

# Get the full path to the pingsweep script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PINGSWEEP_PATH="$SCRIPT_DIR/pingsweep"

# Check if ZSHRC exists
if [ ! -f "$ZSHRC" ]; then
    echo -e "${YELLOW}Warning: $ZSHRC does not exist.${NC}"
    echo -e "Creating $ZSHRC file..."
    touch "$ZSHRC"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Unable to create $ZSHRC. Check permissions.${NC}"
        exit 1
    fi
fi

# Backup ZSHRC before modifying
cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"

# Remove any old pingsweep() function from ZSHRC
awk '/^pingsweep\(\)/ {in_func=1; brace=0} in_func {brace+=gsub(/{/,"{"); brace-=gsub(/}/,"}"); if (brace<=0 && /}/) {in_func=0; next} next} {print}' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

# Remove any previous sourcing guard block from ZSHRC
awk 'BEGIN{in_block=0} /^# Source \.zshfunc with guard/ {in_block=1} in_block && /fi/ {in_block=0; next} !in_block' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

# Ensure .zshfunc exists and update pingsweep function
if [ ! -f "$ZSHFUNC" ]; then
    touch "$ZSHFUNC"
fi
awk '/^pingsweep\(\)/ {in_func=1; brace=0} in_func {brace+=gsub(/{/,"{"); brace-=gsub(/}/,"}"); if (brace<=0 && /}/) {in_func=0; next} next} {print}' "$ZSHFUNC" > "$ZSHFUNC.tmp" && mv "$ZSHFUNC.tmp" "$ZSHFUNC"
cat "$PINGSWEEP_PATH" >> "$ZSHFUNC"
chmod 600 "$ZSHFUNC"

# Add guarded sourcing of .zshfunc to ZSHRC
# Only one block will exist due to the removal above
guard_block='# Source .zshfunc with guard\nif [ -f "$HOME/.zshfunc" ] && ! [[ "$ZSHFUNC_SOURCED" == "1" ]]; then\n    export ZSHFUNC_SOURCED=1\n    source "$HOME/.zshfunc"\nfi'
echo -e "\n$guard_block" >> "$ZSHRC"

echo -e "${GREEN}Successfully installed/updated pingsweep function in $ZSHFUNC and updated $ZSHRC!${NC}"
echo -e "To start using it, either:"
echo -e "  1. Restart your terminal"
echo -e "  2. Run: ${YELLOW}source $ZSHRC${NC}" 

# If using dotfiles, run install.sh to apply changes
if [ "$DOTFILES_USED" = "1" ] && [ -f "$HOME/dotfiles/install.sh" ]; then
    echo -e "${YELLOW}Detected dotfiles setup. Running $HOME/dotfiles/install.sh to apply changes...${NC}"
    bash "$HOME/dotfiles/install.sh"
fi 

#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

# Function to test if a command exists
test_command() {
    local cmd="$1"
    local description="${2:-$cmd}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $description"
        ((FAILED++))
    fi
}

# Function to test if a file exists
test_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $description"
        ((FAILED++))
    fi
}

# Function to test if a directory exists
test_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $description"
        ((FAILED++))
    fi
}

echo -e "${YELLOW}Testing Shell Bling Ubuntu Installation${NC}"
echo "========================================"
echo

# Test shell and terminal utilities
echo "Testing shells and terminal utilities..."
test_command "fish" "Fish shell"
test_command "starship" "Starship prompt"
test_command "tmux" "tmux terminal multiplexer"
test_command "kitty" "Kitty terminal emulator"
test_command "xclip" "xclip clipboard utility"

echo

# Test search and file utilities
echo "Testing search and file utilities..."
test_command "fzf" "fzf fuzzy finder"
test_command "fd" "fd (fast find)"
test_command "rg" "ripgrep (rg)"
test_command "zoxide" "zoxide (smart cd)"
test_command "lsd" "lsd (modern ls)"
test_command "tree" "tree directory viewer"
test_command "bat" "bat (better cat)"

echo

# Test text editors
echo "Testing text editors..."
test_command "micro" "micro editor"
test_command "vim" "vim editor"
test_command "nvim" "neovim editor"
test_command "hx" "helix editor"

echo

# Test development tools
echo "Testing development tools..."
test_command "git" "git version control"
test_command "lazygit" "lazygit"
test_command "delta" "git-delta"
test_command "entr" "entr file watcher"

echo

# Test data manipulation tools
echo "Testing data manipulation tools..."
test_command "jq" "jq JSON processor"
test_command "gron" "gron JSON flattener"
test_command "csvcut" "csvkit (testing csvcut)"

echo

# Test system monitoring tools
echo "Testing system monitoring tools..."
test_command "htop" "htop process viewer"
test_command "lnav" "lnav log viewer"
test_command "btm" "bottom system monitor"

echo

# Test help utilities
echo "Testing help utilities..."
test_command "tldr" "tldr help pages"
test_command "cheat" "cheat sheets"

echo

# Test configuration files
echo "Testing configuration files..."
test_file "$HOME/.config/fish/config.fish" "Fish configuration"
test_file "$HOME/.config/kitty/kitty.conf" "Kitty configuration"
test_file "$HOME/.config/nvim/init.lua" "Neovim configuration (LazyVim)"
test_file "$HOME/.gitconfig" "Git configuration with delta"
test_directory "$HOME/.fzf" "fzf installation directory"
test_directory "$HOME/.local/share/fonts" "Fonts directory"
test_file "$HOME/.local/share/fonts/FiraCodeNerdFont-Retina.ttf" "FiraCode Nerd Font"

echo

# Test symlinks
echo "Testing symlinks..."
if [ -L "$HOME/.local/bin/fd" ] && [ "$(readlink -f "$HOME/.local/bin/fd")" = "$(which fdfind)" ]; then
    echo -e "${GREEN}✓${NC} fd symlink to fdfind"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} fd symlink to fdfind"
    ((FAILED++))
fi

echo
echo "========================================"
echo -e "Tests completed: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"

# Exit with non-zero status if any tests failed
if [ $FAILED -gt 0 ]; then
    exit 1
fi
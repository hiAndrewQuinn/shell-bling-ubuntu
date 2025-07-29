# Shell Bling Ubuntu Testing Guide

This guide provides detailed instructions for testing Shell Bling Ubuntu using Docker containers. All commands are designed to be idempotent - you can run them multiple times safely.

## Prerequisites

- Docker installed and running
- Docker Compose installed (usually comes with Docker Desktop)
- Git (to clone this repository)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/hiAndrewQuinn/shell-bling-ubuntu.git
cd shell-bling-ubuntu

# Start a test environment
docker-compose up -d

# Enter the container
docker-compose exec shell-bling fish

# When done, clean up
docker-compose down
docker rmi shell-bling-test:24.04
```

## Testing Methods

### Method 1: Docker Compose (Recommended)

Docker Compose provides the easiest way to spin up and manage test containers.

#### Setup and Usage

```bash
# 1. Start the container in detached mode
docker-compose up -d

# 2. Enter the container with fish shell
docker-compose exec shell-bling fish

# 3. Inside the container, you can:
#    - Test individual tools (fzf, rg, fd, etc.)
#    - Run the test suite: ./test-installations.sh
#    - Explore configurations in ~/.config/
#    - Try out keyboard shortcuts (Ctrl+R for history search)

# 4. Exit the container (but keep it running)
exit

# 5. Re-enter anytime
docker-compose exec shell-bling fish

# 6. View container logs
docker-compose logs

# 7. Restart the container
docker-compose restart
```

#### Testing Different Ubuntu Versions

```bash
# Test with Ubuntu 22.04
UBUNTU_VERSION=22.04 docker-compose up -d
docker-compose exec shell-bling fish
# When done:
docker-compose down
docker rmi shell-bling-test:22.04

# Test with Ubuntu 24.04 (default)
docker-compose up -d
docker-compose exec shell-bling fish
# When done:
docker-compose down
docker rmi shell-bling-test:24.04
```

#### Complete Teardown

```bash
# Stop and remove containers
docker-compose down

# Remove the built images
docker rmi shell-bling-test:24.04
docker rmi shell-bling-test:22.04  # if you tested 22.04

# Remove any dangling images (optional)
docker image prune -f
```

### Method 2: Interactive Dockerfile

This method lets you manually experience the fish configuration step, including the editor selection prompt.

#### Setup and Usage

```bash
# 1. Build the interactive image
docker build -f Dockerfile.interactive -t shell-bling-interactive .

# 2. Run the container
docker run -it --name shell-bling-test shell-bling-interactive

# 3. Inside the container, complete the fish setup manually
/tmp/shell-bling.fish
# This will prompt you to select your default editor using fzf

# 4. Exit the container
exit

# 5. Re-enter to see the complete setup with greeting
docker start shell-bling-test
docker exec -it shell-bling-test fish

# 6. Run tests
./test-installations.sh
```

#### Teardown

```bash
# Stop and remove the container
docker stop shell-bling-test
docker rm shell-bling-test

# Remove the image
docker rmi shell-bling-interactive

# Clean up any dangling images (optional)
docker image prune -f
```

### Method 3: One-off Testing

For quick tests without persistent containers.

#### Automated Test Run

```bash
# Build and run tests in one command
docker build -t shell-bling-test . && \
docker run --rm shell-bling-test bash /home/testuser/test-installations.sh

# Clean up
docker rmi shell-bling-test
```

#### Interactive Exploration

```bash
# Build and enter container interactively
docker build -t shell-bling-test . && \
docker run -it --rm shell-bling-test fish

# No cleanup needed (--rm removes container automatically)
# But you may want to remove the image:
docker rmi shell-bling-test
```

## What to Test

Once inside a container, here are things you can try:

### Basic Tool Verification

```bash
# Run the comprehensive test suite
./test-installations.sh

# Test individual tools
fzf --version
rg --version
fd --version
bat --version
```

### Interactive Features

```bash
# Test fuzzy history search (if you have command history)
# Press Ctrl+R and start typing

# Test fuzzy directory navigation
# Press Alt+C to change directories with fzf

# Test file finding
fd shell-bling
rg "fish" ~/.config/

# Test syntax highlighting
bat ~/.config/fish/config.fish
```

### Editor Testing

```bash
# Test different editors
micro ~/.bashrc
vim ~/.bashrc  
nvim ~/.config/fish/config.fish
hx ~/.gitconfig
```

### Development Tools

```bash
# Test git integration
git status
git log --oneline | head -5

# Test lazygit (if git repository is available)
lazygit
```

## Troubleshooting

### Container Won't Start

```bash
# Check if Docker is running
docker version

# Check for port conflicts
docker-compose ps

# View detailed logs
docker-compose logs -f
```

### Container Runs But Tools Don't Work

```bash
# Enter with bash instead of fish to debug
docker-compose exec shell-bling bash

# Check if fish is properly installed
which fish
fish --version

# Check user shell setting
echo $SHELL
```

### Out of Disk Space

```bash
# Clean up stopped containers
docker container prune -f

# Clean up unused images
docker image prune -f

# Clean up unused volumes
docker volume prune -f

# Nuclear option - clean everything unused
docker system prune -af
```

### Permission Issues

```bash
# The container runs as 'testuser' with sudo privileges
# If you need root access:
docker-compose exec --user root shell-bling bash
```

## Performance Notes

- **First run**: Building the image takes 5-10 minutes (downloads packages, compiles tools)
- **Subsequent runs**: Starting containers takes seconds
- **Disk usage**: Each built image is approximately 2-3 GB
- **Memory usage**: Containers use minimal RAM when idle

## Integration with Development Workflow

### Testing Script Changes

```bash
# Make changes to shell scripts locally
# The docker-compose.yml mounts scripts as volumes

# Restart container to test changes
docker-compose restart
docker-compose exec shell-bling fish

# Test your changes
./test-installations.sh
```

### Continuous Testing

```bash
# Set up for rapid iteration
docker-compose up -d

# Make changes, then quickly test:
docker-compose exec shell-bling bash /home/testuser/test-installations.sh

# When satisfied, tear down
docker-compose down && docker rmi shell-bling-test:24.04
```
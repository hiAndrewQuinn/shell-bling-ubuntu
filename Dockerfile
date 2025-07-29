# Use Ubuntu as base image with version argument
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

# Set environment to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages required for the installation scripts
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for testing (mimics real Ubuntu installation)
RUN useradd -m -s /bin/bash testuser && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Copy installation scripts
COPY shell-bling-sudo.bash /tmp/
COPY shell-bling-user.bash /tmp/
COPY shell-bling.fish /tmp/
COPY show_random_whatis.fish /tmp/

# Make scripts executable
RUN chmod +x /tmp/*.bash /tmp/*.fish

# Run the sudo installation script
RUN /tmp/shell-bling-sudo.bash

# Switch to testuser for remaining installations
USER testuser
WORKDIR /home/testuser

# Run the user installation script
RUN /tmp/shell-bling-user.bash

# Set fish as the default shell for testuser
USER root
RUN chsh -s $(which fish) testuser
USER testuser

# Copy test script that will be run to verify installations
COPY --chown=testuser:testuser test-installations.sh /home/testuser/

# The fish configuration script needs to be run interactively due to editor selection
# We'll handle this in the test script or CI workflow

# Default to fish shell
SHELL ["/usr/bin/fish", "-c"]
CMD ["/usr/bin/fish"]
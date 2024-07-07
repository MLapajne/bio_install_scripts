# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

# Set environment variable to avoid user prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    libgomp1 \
    git \
    make \
    g++ \
    bash \
    openjdk-17-jdk \
    git-lfs \
    curl \
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# Copy the installation script into the container
COPY install_conda_flye.sh /install_conda_flye.sh

# Make the script executable
RUN chmod +x /install_conda_flye.sh

# Run the installation script
RUN /install_conda_flye.sh

# Set the entrypoint to bash to keep the container running
ENTRYPOINT ["bash"]
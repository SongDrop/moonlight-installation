#!/bin/bash

# Exit on any error
set -e

# Function to install required dependencies
function install_dependencies() {
    echo "Updating package list..."
    sudo apt update -y

    echo "Installing necessary dependencies for APT..."

    # Install required packages for APT build
    declare -a dependencies=(
        build-essential
        libapt-pkg-dev
        libcurl4-openssl-dev
        libglib2.0-dev
        libssl-dev
        pkg-config
        git
        cmake  # You can comment this out if you prefer not to install CMake
    )

    for dependency in "${dependencies[@]}"; do
        echo "Installing $dependency..."
        sudo apt install -y "$dependency"
    done
}

# Function to install packages with error handling and automatic confirmation
function install_packages() {
    echo "Updating the system and preparing to install additional packages..."

    if ! command -v apt &> /dev/null; then
        echo "APT is not available. Please install it manually."
        exit 1
    fi

    sudo apt update -y

    declare -a packages=(
        make
        gcc
        git
        libavcodec-dev
        libavformat-dev
        libavutil-dev
        libboost-dev
        libcurl4-openssl-dev
        libglib2.0-dev
        libgles2-mesa-dev
        libjpeg-dev
        libjsoncpp-dev
        libsdl2-dev
        libx11-dev
        libxext-dev
        pkg-config
        python3-dev
        qtbase5-dev
        libxi-dev
        libxrandr-dev
        mesa-utils
        libopus-dev  # Added Opus for audio encoding support
    )

    for package in "${packages[@]}"; do
        echo "Installing $package..."
        if ! sudo apt install -y "$package"; then
            echo "$package installation failed. Please install it manually."
            read -p "Do you want to continue? (y/n): " choice
            if [[ "$choice" != "y" ]]; then
                echo "Exiting the script."
                exit 1
            fi
        fi
    done
}

# Function to clone and build Moonlight
function build_moonlight() {
    echo "Cloning Moonlight Embedded repository..."
    if ! git clone --recursive https://github.com/irtimmer/moonlight-embedded.git; then
        echo "Failed to clone the Moonlight repository. Please check your internet connection."
        exit 1
    fi
    cd moonlight-embedded

    mkdir build && cd build
    echo "Configuring the build..."
    if ! cmake ..; then
        echo "CMake configuration failed. Please check the output for errors."
        exit 1
    fi
    echo "Building Moonlight Embedded with parallel jobs for faster installation..."
    if ! make -j$(nproc); then
        echo "Build failed. Please check the output for errors."
        exit 1
    fi

    echo "Installing Moonlight Embedded..."
    sudo make install
}

# Clean up
function cleanup() {
    echo "Cleaning up..."
    cd ../../
}

# Optional: Install xpad for Xbox controller support
function install_xpad() {
    echo "Installing xpad for controller support..."
    if ! sudo apt install -y xserver-xorg-input-xpad; then
        echo "xserver-xorg-input-xpad installation failed. Please install it manually."
    fi
}

# Main script execution

# Update dependencies
install_dependencies

# Install packages (if APT is available)
install_packages

# Build Moonlight
build_moonlight

# Optional: Install xpad for controller support
install_xpad

# Clean up
cleanup

# Final instructions
echo "Moonlight Embedded installation complete!"
echo "You can now configure Moonlight using the command: moonlight pair <your-pc-ip>"
echo "For controller support, make sure to connect your controller and configure it as needed."

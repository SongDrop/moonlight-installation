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
        libopus-dev
        libevdev-dev
        libavahi-client-dev
        libasound2-dev
        libudev-dev
        libexpat1-dev
        libpulse-dev
        uuid-dev
        libavcodec-dev
        libavutil-dev
        libvdpau-dev
        libva-dev
        libsdl2-dev
        libcec-dev
    )

    for dependency in "${dependencies[@]}"; do
        echo "Installing $dependency..."
        sudo apt install -y "$dependency" || {
            echo "$dependency installation failed. Exiting."
            exit 1
        }
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
        libopus-dev
        libevdev-dev
        libavahi-client-dev
        libexpat1-dev
        libpulse-dev
        uuid-dev
    )

    for package in "${packages[@]}"; do
        echo "Installing $package..."
        sudo apt install -y "$package" || {
            echo "$package installation failed. Exiting."
            exit 1
        }
    done
}

# Function to clone and build Moonlight
function build_moonlight() {
    echo "Cloning Moonlight Embedded repository..."
    if ! git clone --recursive https://github.com/moonlight-stream/moonlight-embedded.git; then
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


# Main script execution

# Update dependencies
install_dependencies

# Install packages (if APT is available)
install_packages

# Build Moonlight
build_moonlight


# Final instructions
echo "Moonlight Embedded installation complete!"
echo "You can now configure Moonlight using the command: moonlight pair <your-pc-ip>"
echo "For controller support, make sure to connect your controller and configure it as needed."

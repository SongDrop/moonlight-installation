#!/bin/bash

# Exit on any error
set -e

# Function to install required dependencies
function install_dependencies() {
    echo "Updating package list..."
    sudo apt update -y

    # Install necessary dependencies for APT build
    declare -a dependencies=(
        build-essential
        libapt-pkg-dev
        libcurl4-openssl-dev
        libglib2.0-dev
        libssl-dev
        pkg-config
        git
        cmake
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
        nodejs
        npm
    )

    for dependency in "${dependencies[@]}"; do
        echo "Installing $dependency..."
        sudo apt install -y "$dependency" || {
            echo "$dependency installation failed. Exiting."
            exit 1
        }
    done
}

# Function to install Moonlight
function install_moonlight() {
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
    echo "Building Moonlight Embedded..."
    if ! make -j$(nproc); then
        echo "Build failed. Please check the output for errors."
        exit 1
    fi

    echo "Installing Moonlight Embedded..."
    sudo make install
}

# Function to install Socket.IO server
function install_socketio_server() {
    echo "Setting up Socket.IO server..."

    # Create a directory for the server
    mkdir -p ~/socket-server
    cd ~/socket-server

    # Initialize npm project
    npm init -y

    # Install Socket.IO
    npm install socket.io

    # Create the server.js file
    cat > server.js << EOL
const io = require('socket.io')(3000);  // Set your desired port for Socket.IO

// Listen for incoming socket connections
io.on('connection', (socket) => {
    console.log('New client connected');
    
    // Handle keyboard input
    socket.on('keyboard', (key) => {
        console.log('Received keyboard input: ' + key);
        // Forward the input to Moonlight (use xdotool or similar)
        require('child_process').execSync('xdotool key ' + key);
    });
    
    // Handle mouse input
    socket.on('mouse', (coords) => {
        console.log('Received mouse input at x: ' + coords.x + ', y: ' + coords.y);
        // Simulate mouse movement
        require('child_process').execSync('xdotool mousemove ' + coords.x + ' ' + coords.y);
    });

    socket.on('disconnect', () => {
        console.log('Client disconnected');
    });
});

console.log('Socket.IO server running on http://localhost:3000');
EOL

    # Run the server in the background
    nohup node server.js &

    echo "Socket.IO server is running on port 3000."
}

# Function to install and configure WebRTC Gateway (Janus)
function install_webrtc_gateway() {
    echo "Installing WebRTC Gateway (Janus)..."
    sudo apt-get install -y build-essential pkg-config libmicrohttpd-dev libjansson-dev libssl-dev libcurl4-openssl-dev libwebsockets-dev libavcodec-dev libavformat-dev libavutil-dev

    # Clone Janus WebRTC repository
    git clone https://github.com/meetecho/janus-gateway
    cd janus-gateway

    # Build Janus WebRTC server
    ./autogen.sh
    ./configure
    make
    sudo make install
}

# Function to configure FFmpeg for WebRTC streaming
function configure_ffmpeg_webrtc() {
    echo "Setting up FFmpeg for WebRTC streaming..."
    sudo apt install -y ffmpeg

    # Get the local IP address of the server (used for RTMP stream URL)
    local_ip=$(hostname -I | awk '{print $1}')
    echo "Detected local IP address: $local_ip"

    # Capture the whole screen where Moonlight is running and stream via RTMP to Janus (WebRTC)
    echo "Starting FFmpeg stream to Janus WebRTC Gateway at rtmp://$local_ip:5000/live/stream"
    ffmpeg -f x11grab -video_size 1920x1080 -i :0.0 -f flv rtmp://$local_ip:5000/live/stream
}

# Main script execution
echo "Starting the installation process for Moonlight Embedded..."

# Update dependencies
install_dependencies

# Install Moonlight
install_moonlight

# Install Socket.IO server for input handling
install_socketio_server

# Install and configure WebRTC Gateway (Janus)
install_webrtc_gateway

# Instructions for pairing Moonlight with Sunshine
echo "You can now configure Moonlight using the command: moonlight pair <your-pc-ip>"
echo "Please enter the IP address of your PC and provide the 4-digit PIN when prompted in Sunshine."

# Prompt for IP address to stream via WebRTC
echo "Once paired, the server's IP address will be used for the WebRTC stream."
echo "This will stream to the following address: http://<server-ip>:5000"

# Configure FFmpeg for WebRTC (automatically uses server's IP address)
configure_ffmpeg_webrtc

# Instructions for browser
echo "You can now open the following URL in your browser to view the stream:"
echo "http://$local_ip:5000/live/stream"

# Instructions for embedding the iframe and connecting with Socket.IO
echo "You can now embed the following iframe in your webpage for streaming:"
echo "<iframe src='http://$local_ip:5000/live/stream' width='100%' height='100%' frameborder='0'></iframe>"

echo "Alternatively, you can send mouse and keyboard inputs to the stream via Socket.IO."
echo "Connect to the server running on port 3000 to send keyboard and mouse events."
echo "The server's Socket.IO URL is: http://$local_ip:3000"

echo "All required components are installed. Your Moonlight stream should now be available in the browser via WebRTC, and you can interact with the game via mouse/keyboard inputs!"

#!/bin/bash

# ─────────────────────────────────────────────────
# Installer Script (installer.sh)
# ─────────────────────────────────────────────────

# Function to download and install the shell scripts
download_scripts() {
    echo "Downloading setup scripts..."

    # URLs for the raw setup scripts in the GitHub repository
    BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/tsugumi-sys/rocket/refs/heads/main/setup_backend.sh"
    WEB_SCRIPT_URL="https://raw.githubusercontent.com/tsugumi-sys/rocket/refs/heads/main/setup_web.sh"
    PROJECT_SCRIPT_URL="https://raw.githubusercontent.com/tsugumi-sys/rocket/refs/heads/main/setup_project.sh"

    # Download the scripts
    curl -fsSL $PROJECT_SCRIPT_URL -o setup_project.sh
    curl -fsSL $BACKEND_SCRIPT_URL -o setup_backend.sh
    curl -fsSL $WEB_SCRIPT_URL -o setup_web.sh

    # Make them executable
    chmod +x setup_project.sh setup_backend.sh setup_web.sh
}

# Function to run the setup process
run_setup() {
    echo "Running the setup process..."

    # Run the main setup script
    ./setup_project.sh

    # Check if the setup completed successfully
    if [ $? -ne 0 ]; then
        echo "Error during setup process."
        exit 1
    fi
}

# Function to clean up downloaded files
cleanup() {
    echo "Cleaning up..."
    rm -f setup_project.sh setup_backend.sh setup_web.sh
}

# Main execution
download_scripts
run_setup
cleanup

echo "Installation completed successfully!"


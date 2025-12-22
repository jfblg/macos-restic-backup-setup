#!/bin/bash

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Restic
if ! command -v restic &> /dev/null; then
    echo "Installing Restic..."
    brew install restic
else
    echo "Restic is already installed."
fi

# Verify installation
restic version

#!/bin/bash

set -e

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo uermod -aG docker ubuntu

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean
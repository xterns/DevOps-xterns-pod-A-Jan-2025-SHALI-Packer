#!/bin/bash

# 001-critical-standards.sh: Initial system preparation and basic hardening.

# Error handler function
error_handler() {
  echo "Error occurred in script at line: $1. Exiting."
  exit 1
}

# Trap the ERR signal to catch errors and call the error_handler function
trap 'error_handler $LINENO' ERR

set -e

log_file="/var/log/001-critical-standards.log"

# Logging function
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | sudo tee -a $log_file
}

log "Starting 001-critical-standards.sh: Initial system preparation and basic hardening."

# Determine the SSH service name
get_ssh_service_name() {
  if sudo systemctl list-unit-files | grep -q "^ssh.service"; then
    echo "ssh"
  elif sudo systemctl list-unit-files | grep -q "^sshd.service"; then
    echo "sshd"
  else
    echo ""
  fi
}

# Disable unnecessary services
disable_services() {
  log "Disabling unused services..."
  services=("bluetooth" "cups" "nfs-server" "rpcbind")
  for service in "${services[@]}"; do
    if sudo systemctl is-enabled "$service" &>/dev/null; then
      sudo systemctl disable "$service"
      log "Disabled $service service."
    else
      log "$service service is already disabled or not found."
    fi
  done
}

# Install basic tools and perform updates
install_tools_and_update() {
  log "Installing basic tools and updating system..."
  if [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y curl vim git
  elif [ -f /etc/redhat-release ]; then
    sudo yum update -y && sudo yum install -y curl vim git
  else
    log "Unsupported system type. Exiting."
    exit 1
  fi
  log "Basic tools installed and system updated."
}

# Set up a basic system log directory
setup_log_directory() {
  log "Setting up log directory..."
  sudo mkdir -p /var/log/critical-standards
  sudo chmod 700 /var/log/critical-standards
  log "Log directory created at /var/log/critical-standards."
}

# Secure SSH by disabling root login and password authentication
secure_ssh() {
  log "Securing SSH configuration..."
  ssh_config="/etc/ssh/sshd_config"
  sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' "$ssh_config"
  sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config"

  ssh_service=$(get_ssh_service_name)
  if [ -z "$ssh_service" ]; then
    log "SSH service not found. Skipping restart."
  else
    sudo systemctl restart "$ssh_service"
    log "SSH configuration updated and $ssh_service service restarted."
  fi
}

# Clean up temporary files
clean_temp_files() {
  log "Cleaning up temporary files..."
  sudo rm -rf /tmp/*
  log "Temporary files cleaned."
}

# Function to configure firewall
configure_firewall() {
  echo "configuring firewall..."
  # Check if the system is Debian-based
  if [ -f /etc/debian_version ]; then
    apt install -y ufw

    #define the ufw commands
    commands=(
      "ufw default deny incoming"
      "ufw default allow outgoing"
      "ufw allow ssh"
      "ufw allow http"
      "ufw allow https"
      "yes | ufw enable"
    )

    #Execute each UFW command
    for cmd in "${commands[@]}"; do
      log "Executing: $cmd"
      if ! eval $cmd; then
        log "Error! failed to execute '$cmd'."
        exit 1
      fi
    done
   
    # Configure firewall rules for RedHat-based systems using iptables or ufw
  elif [ -f /etc/redhat-release ]; then
    yum install -y firewalld
    
    #start and enable firewalld
    systemctl start firewalld 
    systemctl enable firewalld
    
    commands=(
      "firewall-cmd --set-default-zone=public"
      "firewall-cmd --permanent --add-service=ssh"
      "firewall-cmd --permanent --add-service=http"
      "firewall-cmd --permanent --add-service=https"
      "firewall-cmd --reload"
    )

    for cmd in "${commands[@]}"; do
      log "Executing $cmd"
      if ! eval "$cmd"; then 
        log "Error! failed to execute '$cmd'."
        return 1
      fi
    done 
  fi
  # Capture the exit code
  exit_code=$?
  # Return the exit code
  return $exit_code
}

# Main execution
disable_services
install_tools_and_update
setup_log_directory
secure_ssh

configure_firewall
# Check the exit code of the previous function
if [ $? -ne 0 ]; then
  # Log the error and exit if the function failed
  echo "Failed to configure firewall. Exiting..."
  exit 1
fi

clean_temp_files

log "001-critical-standards.sh completed successfully."

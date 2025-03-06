#!/bin/bash

# Customized critical_standards.sh for SHALI Project
# Focused on essential security and logging configurations.

# Error handler function
error_handler() {
  echo "Error occurred in script at line: $1. Exiting."
  exit 1
}

# Trap errors and handle them gracefully
trap 'error_handler $LINENO' ERR

set -e  # Exit on command errors

log_file="/var/log/shali_hardening.log"

# Logging function
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | sudo tee -a $log_file
}

### Custom Functions ###

# Function to enforce password policies
enforce_password_policy() {
  log "Enforcing password policy..."

  sudo bash -c 'echo "PASS_MAX_DAYS 90" >> /etc/login.defs'
  sudo bash -c 'echo "PASS_MIN_DAYS 10" >> /etc/login.defs'
  sudo bash -c 'echo "PASS_WARN_AGE 7" >> /etc/login.defs'

  for user in $(awk -F: '{if ($3 >= 1000) print $1}' /etc/passwd); do
    sudo chage --maxdays 90 --mindays 10 --warndays 7 "$user"
  done

  log "Password policy enforced successfully."
}


# Function to configure logging

# Function to configure time synchronization
configure_time_sync() {
  log "Configuring time synchronization with Chrony..."

  sudo apt-get update && sudo apt-get install -y chrony
  sudo systemctl enable chrony && sudo systemctl restart chrony

  if sudo chronyc tracking; then
    log "Time synchronization validated successfully."
  else
    log "Time synchronization validation failed."
    exit 1
  fi
}


# Function to disable unused USB ports
disable_usb() {
  log "Disabling USB ports..."

  echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/disable-usb-storage.conf > /dev/null
  sudo update-initramfs -u

  log "USB ports disabled."
}


# Function to remove insecure tools
remove_insecure_tools() {
  log "Removing insecure tools (telnet, ftp)..."

  sudo apt-get remove -y telnet ftp && sudo apt-get autoremove -y

  log "Insecure tools removed successfully."
}

# Function to monitor user activity
enable_user_activity_monitoring() {
  log "Setting up user activity monitoring..."

  sudo apt-get install -y auditd
  sudo systemctl enable auditd && sudo systemctl start auditd
  sudo auditctl -e 1

  log "User activity monitoring enabled."
}

### Execution Flow ###
log "Starting critical standards setup for SHALI..."

enforce_password_policy
configure_time_sync
disable_usb
remove_insecure_tools
enable_user_activity_monitoring

log "Critical standards setup for SHALI completed successfully."
#!/bin/bash

# ====================================================
# Network Diagnostic Tool
# Author: Gabriel Paniagua Castro
# Company: RE&COM SA
# Description:
#   Automated packet loss and latency diagnostic tool.
#   - Auto-discovers network hops (user-defined, default 5).
#   - Tests multiple targets using 'mtr'.
#   - Outputs to console with color coding and timestamp.
#   - Saves detailed logs to a timestamped file (clean, no color codes).
#   - Exports summary CSV report.
#   - Requires sudo privileges if available (runs without if not).
# ====================================================

# === Functions ===

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Clean print function: color for terminal, clean for log
print_message() {
  local message="$1"
  local color="$2"
  # Print to terminal with color if specified
  if [ -n "$color" ]; then
    echo -e "${color}${message}${NC}"
  else
    echo -e "$message"
  fi
  # Print to log file without color codes
  echo "$message" >> "$LOG_FILE"
}

# Check for required commands
check_dependencies() {
  MISSING=0
  for cmd in mtr traceroute bc; do
    if ! command -v $cmd &> /dev/null; then
      print_message "Missing required package: $cmd" "$RED"
      MISSING=1
    fi
  done
  if [[ $MISSING -eq 1 ]]; then
    print_message "Please install the missing packages and run the script again." "$RED"
    exit 1
  fi
}

# Auto-discover user-defined number of hops
discover_hosts() {
  print_message "Discovering network hops (up to $HOPS_TO_CHECK)..." "$GREEN"
  TARGET="8.8.8.8"
  HOSTS=($(traceroute -n -w 1 -q 1 $TARGET | awk 'NR>1 {print $2}' | head -n $HOPS_TO_CHECK))
  HOSTS+=("8.8.8.8" "1.1.1.1") # Add Google DNS and Cloudflare
  print_message "Discovered hosts:"
  for HOST in "${HOSTS[@]}"; do
    print_message "  - $HOST"
  done
}

# Diagnostic run
run_diagnostics() {
  print_message ""
  print_message "$(timestamp) - Starting diagnostic run"
  print_message ""

  # CSV Header
  echo "Timestamp,Host,Packet Loss %,Average Latency (ms)" > "$CSV_FILE"

  for HOST in "${HOSTS[@]}"; do
    print_message "Testing: $HOST" "$YELLOW"

    OUTPUT=$($SUDO_CMD mtr -n --report --report-cycles "$PROBES" "$HOST")
    echo "$OUTPUT" >> "$LOG_FILE"
    echo "$OUTPUT"

    LOSS=$(echo "$OUTPUT" | grep -Eo '[0-9]+\.?[0-9]*% packet loss' | awk '{print $1}')
    if [[ "$LOSS" == "" ]]; then
      LOSS="0%"
    fi

    AVG_LATENCY=$(echo "$OUTPUT" | tail -n 1 | awk '{print $5}')
    if [[ "$AVG_LATENCY" == "" ]]; then
      AVG_LATENCY="0"
    fi

    # Write to CSV
    echo "$(timestamp),$HOST,$LOSS,$AVG_LATENCY" >> "$CSV_FILE"

    # Color code based on packet loss
    LOSS_VAL=$(echo "$LOSS" | tr -d '%')
    if (( $(echo "$LOSS_VAL > 50" | bc -l) )); then
      COLOR=$RED
    elif (( $(echo "$LOSS_VAL > 10" | bc -l) )); then
      COLOR=$YELLOW
    else
      COLOR=$GREEN
    fi

    print_message "Packet Loss: ${LOSS}" "$COLOR"
    print_message "Average Latency: ${AVG_LATENCY} ms"
    print_message "----------------------------------------"
  done

  print_message ""
  print_message "$(timestamp) - Diagnostic run complete"
  print_message ""
}

# Introduction and confirmation
introduction() {
  print_message "Network Diagnostic Tool - Preparation" "$GREEN"
  print_message "Author: Gabriel Paniagua Castro"
  print_message "Company: RE&COM SA"
  print_message ""
  print_message "This script will perform the following actions:"
  print_message "1. Auto-discover up to user-defined number of network hops."
  print_message "2. Run packet loss and latency diagnostics using mtr."
  print_message "3. Display results in color-coded format."
  print_message "4. Save all output to a timestamped log file."
  print_message "5. Export summary results to CSV."
  print_message "6. Require sudo privileges for running mtr if available."
  print_message ""
  print_message "Required packages:"
  print_message "- traceroute"
  print_message "- mtr"
  print_message "- bc"
  print_message ""
  print_message "Please make sure these packages are installed before proceeding."
  print_message ""

  read -p "Do you want to continue? (y/n): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    print_message "Aborted by user." "$RED"
    exit 1
  fi
}

# === Main Script ===

# Prepare log and CSV files
LOG_FILE="network_diagnostic_$(date +'%Y%m%d_%H%M%S').log"
CSV_FILE="network_diagnostic_$(date +'%Y%m%d_%H%M%S').csv"

# Welcome & introduction
introduction

# Dependency check
check_dependencies

# Detect if sudo is available
SUDO_CMD=""
if command -v sudo &> /dev/null; then
  SUDO_CMD="sudo"
else
  print_message "Warning: 'sudo' command not found. Running without sudo. Results might be limited." "$YELLOW"
fi

print_message "Log file: $LOG_FILE"
print_message "CSV file: $CSV_FILE"

# User input for number of hops
read -p "Enter number of network hops to check (default 5): " HOPS_TO_CHECK
HOPS_TO_CHECK=${HOPS_TO_CHECK:-5}

# User input for number of probes
read -p "Enter number of probes per host (default 50): " PROBES
PROBES=${PROBES:-50}

# Discover hosts
discover_hosts

# Run diagnostics (single run)
print_message "Starting diagnostic run..." "$YELLOW"
run_diagnostics

print_message "All diagnostics completed."
print_message "Log saved to: $LOG_FILE"
print_message "CSV report saved to: $CSV_FILE" "$GREEN"

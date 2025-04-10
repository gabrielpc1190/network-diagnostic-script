#!/bin/bash

# ====================================================
# Network Diagnostic Tool
# Author: Gabriel Paniagua Castro
# Company: RE&COM SA
# Description:
#   Automated packet loss and latency diagnostic tool.
#   - Auto-discover user-defined number of network hops.
#   - Test multiple targets using 'mtr'.
#   - Outputs to console with color coding and timestamp.
#   - Saves detailed logs and CSV reports.
#   - Includes min, max, avg, stdev latency.
#   - Requires sudo if available.
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
  echo -e "${color}${message}${NC}"
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

# Auto-discover hops
discover_hosts() {
  print_message "Discovering network hops (up to $HOPS_TO_CHECK)..." "$GREEN"
  TARGET="8.8.8.8"
  HOSTS=($(traceroute -n -w 1 -q 1 $TARGET | awk 'NR>1 {print $2}' | head -n $HOPS_TO_CHECK))
  HOSTS+=("8.8.8.8" "1.1.1.1")
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
  echo "Timestamp,Host,Packet Loss %,Avg Latency (ms),Min Latency (ms),Max Latency (ms),StDev Latency (ms)" > "$CSV_FILE"

  for HOST in "${HOSTS[@]}"; do
    print_message "Testing: $HOST" "$YELLOW"

    OUTPUT=$($SUDO_CMD mtr -n --report --report-cycles "$PROBES" "$HOST")
    echo "$OUTPUT" >> "$LOG_FILE"
    echo "$OUTPUT"

    # Extract values
    LOSS=$(echo "$OUTPUT" | grep -Eo '[0-9]+\.?[0-9]*% packet loss' | awk '{print $1}')
    [ -z "$LOSS" ] && LOSS="0%"

    STATS_LINE=$(echo "$OUTPUT" | tail -n 1)
    AVG_LATENCY=$(echo "$STATS_LINE" | awk '{print $5}')
    MIN_LATENCY=$(echo "$STATS_LINE" | awk '{print $6}')
    MAX_LATENCY=$(echo "$STATS_LINE" | awk '{print $7}')
    STDEV_LATENCY=$(echo "$STATS_LINE" | awk '{print $8}')

    # Write to CSV
    echo "$(timestamp),$HOST,$LOSS,$AVG_LATENCY,$MIN_LATENCY,$MAX_LATENCY,$STDEV_LATENCY" >> "$CSV_FILE"

    # Color packet loss
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
    print_message "Min Latency: ${MIN_LATENCY} ms"
    print_message "Max Latency: ${MAX_LATENCY} ms"
    print_message "StDev Latency: ${STDEV_LATENCY} ms"
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
  print_message "1. Auto-discover user-defined number of network hops."
  print_message "2. Run packet loss and latency diagnostics using mtr."
  print_message "3. Display results in color-coded format."
  print_message "4. Save detailed logs and CSV reports."
  print_message "5. Require sudo privileges if available."
  print_message ""
  print_message "Required packages:"
  print_message "- traceroute"
  print_message "- mtr"
  print_message "- bc"
  print_message ""
  read -p "Do you want to continue? (y/n): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    print_message "Aborted by user." "$RED"
    exit 1
  fi
}

# === Main Script ===

LOG_FILE="network_diagnostic_$(date +'%Y%m%d_%H%M%S').log"
CSV_FILE="network_diagnostic_$(date +'%Y%m%d_%H%M%S').csv"

introduction
check_dependencies

SUDO_CMD=""
if command -v sudo &> /dev/null; then
  SUDO_CMD="sudo"
else
  print_message "Warning: 'sudo' command not found. Running without sudo. Results might be limited." "$YELLOW"
fi

print_message "Log file: $LOG_FILE"
print_message "CSV file: $CSV_FILE"

read -p "Enter number of network hops to check (default 5): " HOPS_TO_CHECK
HOPS_TO_CHECK=${HOPS_TO_CHECK:-5}

read -p "Enter number of probes per host (default 50): " PROBES
PROBES=${PROBES:-50}

discover_hosts
print_message "Starting diagnostic run..." "$YELLOW"
run_diagnostics

print_message "All diagnostics completed."
print_message "Log saved to: $LOG_FILE"
print_message "CSV report saved to: $CSV_FILE" "$GREEN"
print_message ""
print_message "Diagnostics complete — your report is ready!" "$GREEN"
print_message "Review CSV: $CSV_FILE"

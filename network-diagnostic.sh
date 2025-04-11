#!/bin/bash

# ====================================================
# Network Diagnostic Tool (Hardened Production Version)
# Author: Gabriel Paniagua Castro
# Company: RE&COM SA
# Description:
#   - Fast diagnostics using mtr --report
#   - Safe file handling with mktemp
#   - Input validation for security
#   - Clean logs and CSV report
# ====================================================

# === Functions ===

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Safe temp files
LOG_FILE=$(mktemp /tmp/network_diagnostic_log_XXXXXX.log)
CSV_FILE=$(mktemp /tmp/network_diagnostic_csv_XXXXXX.csv)

# Trap for cleanup
cleanup() {
  # Optionally preserve files — we skip deletion for logs
  # rm -f "$TMP_FILE"
  :
}
trap cleanup EXIT

# Timestamp
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Print to console and log
print_message() {
  local message="$1"
  local color="$2"
  echo -e "${color}${message}${NC}"
  echo "$message" >> "$LOG_FILE"
}

# Dependency check
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

# Validate numeric input
validate_numeric() {
  local value="$1"
  local name="$2"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    print_message "Invalid input for $name. Please enter a positive number." "$RED"
    exit 1
  fi
}

# Discover network hops
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

# Parse mtr report output
parse_report() {
  local output="$1"
  local stats_line
  stats_line=$(echo "$output" | grep -E "^\s*[0-9]+\.\|\-\-" | tail -n 1)

  local fields=($stats_line)

  local loss_percent=${fields[2]//%/}
  local avg=${fields[5]}
  local min=${fields[6]}
  local max=${fields[7]}
  local stddev=${fields[8]}

  echo "$loss_percent|$avg|$min|$max|$stddev"
}

# Run diagnostics
run_diagnostics() {
  print_message ""
  print_message "$(timestamp) - Starting diagnostic run"
  print_message ""

  echo "Timestamp,Host,Packet Loss %,Avg Latency (ms),Min Latency (ms),Max Latency (ms),StDev Latency (ms)" > "$CSV_FILE"

  for HOST in "${HOSTS[@]}"; do
    print_message "Testing: $HOST" "$YELLOW"

    RAW_REPORT=$($SUDO_CMD mtr -n --report --report-cycles "$PROBES" "$HOST")
    echo "$RAW_REPORT" >> "$LOG_FILE"

    METRICS=$(parse_report "$RAW_REPORT")
    IFS='|' read -r PACKET_LOSS AVG_LATENCY MIN_LATENCY MAX_LATENCY STDEV_LATENCY <<< "$METRICS"

    echo "$(timestamp),$HOST,${PACKET_LOSS}%,${AVG_LATENCY},${MIN_LATENCY},${MAX_LATENCY},${STDEV_LATENCY}" >> "$CSV_FILE"

    # Color output
    if (( $(echo "$PACKET_LOSS > 50" | bc -l) )); then
      COLOR=$RED
    elif (( $(echo "$PACKET_LOSS > 10" | bc -l) )); then
      COLOR=$YELLOW
    else
      COLOR=$GREEN
    fi

    print_message "Packet Loss: ${PACKET_LOSS}%" "$COLOR"
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

# Intro
introduction() {
  print_message "Network Diagnostic Tool - Preparation" "$GREEN"
  print_message "Author: Gabriel Paniagua Castro"
  print_message "Company: RE&COM SA"
  print_message ""
  print_message "Actions:"
  print_message "1. Auto-discover network hops."
  print_message "2. Perform diagnostics with mtr."
  print_message "3. Save logs and clean CSV report."
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

# === Main ===

introduction
check_dependencies

SUDO_CMD=""
if command -v sudo &> /dev/null; then
  SUDO_CMD="sudo"
else
  print_message "Warning: 'sudo' not found. Running without sudo. Results might be limited." "$YELLOW"
fi

print_message "Log file: $LOG_FILE"
print_message "CSV file: $CSV_FILE"

read -p "Enter number of network hops to check (default 5): " HOPS_TO_CHECK
HOPS_TO_CHECK=${HOPS_TO_CHECK:-5}
validate_numeric "$HOPS_TO_CHECK" "network hops"

read -p "Enter number of probes per host (default 50): " PROBES
PROBES=${PROBES:-50}
validate_numeric "$PROBES" "probes per host"

discover_hosts
print_message "Starting diagnostic run..." "$YELLOW"
run_diagnostics

print_message "All diagnostics completed."
print_message "Log saved to: $LOG_FILE"
print_message "CSV report saved to: $CSV_FILE" "$GREEN"
print_message ""
print_message "Diagnostics complete — your report is ready!"
print_message "Review CSV: $CSV_FILE"

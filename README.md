
# 📡 Network Diagnostic Tool

**Author:** Gabriel Paniagua Castro  
**Company:** RE&COM SA  
**Version:** 1.0  
**Date:** April 2025

----------

## 🔍 Overview

This is a professional-grade network diagnostic tool designed for fast and effective detection of:

-   Packet loss
    
-   Latency issues
    
-   Path analysis (router hops)
    

It is ideal for:

-   Field diagnostics
    
-   Technical support reports
    
-   Fast incident analysis
    
-   Exporting to CSV for management and documentation
    

The script performs:

-   Dynamic network path discovery
    
-   ICMP probe diagnostics using `mtr`
    
-   Color-coded terminal output
    
-   Clean log file generation (no color codes)
    
-   Automatic CSV export for reports
    

----------

## ⚙️ Requirements

Please ensure the following packages are installed **before running the script**:

-   `mtr`
    
-   `traceroute`
    
-   `bc`
    

If `sudo` is available, it will be used to improve diagnostics. If not, the script will still work in user mode.

> **Note:** Root permissions allow `mtr` to provide more accurate results.

----------

## 🚀 Usage

1.  **Make the script executable:**
    

bash

CopyEdit

`chmod +x network_diagnostic.sh` 

2.  **Run the script:**
    

bash

CopyEdit

`./network_diagnostic.sh` 

3.  **Follow the prompts:**
    

-   Confirm you want to proceed.
    
-   Enter number of network hops to check (recommended: 5–10).
    
-   Enter number of probes per host (recommended: 50–100).
    

4.  **Results:**
    

-   ✅ Terminal output with color coding
    
-   📝 Log file (plain text)
    
-   📊 CSV export for sharing or reporting
    

Example output files:

lua

CopyEdit

`network_diagnostic_20250410_203001.log network_diagnostic_20250410_203001.csv` 

----------

## 📂 Output files

File

Description

`.log`

Full raw output of diagnostics (plain text, human-readable)

`.csv`

Summary of results: Host, Packet Loss %, Average Latency (ms), Timestamp

You can open the `.csv` in Excel, Google Sheets, or import it into reporting tools.

----------

## 📝 Recommendations

Task

Recommended Setting

Quick check

10–20 probes

Moderate diagnostics

50 probes

In-depth diagnostics

100–200 probes

Number of hops

5–10 (first router + provider + DNS targets)

----------

## 🔒 Security Notice

-   The script is safe to run.
    
-   It does **not** modify any system settings.
    
-   No external data is transmitted; all tests are local diagnostics.
    

----------

## ✉️ Support

For support or enhancements, contact:

**Gabriel Paniagua Castro**  
RE&COM SA

----------

## ✅ Optional Future Features (Planned)

-   📈 Graphical reports from CSV output
    
-   📨 Email alerts if packet loss detected
    
-   🕒 Scheduled runs (cron support)
    
-   🗃️ Export to JSON for integrations
    

----------

# 🏁 Quick Start Summary

bash

CopyEdit

`chmod +x network_diagnostic.sh
./network_diagnostic.sh` 

Follow the prompts and review the output files:

-   `.log` for full details
    
-   `.csv` for summaries

#!/bin/bash

# Script:  Server Performance Statistics
# Description:  Displays comprehensive server performance metrics
# Author: Akarsh-Kiran-Gowda
# Date: 2026-01-13

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for better readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Print section headers with color
print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Get total CPU usage
get_cpu_usage() {
    print_header "CPU Utilization:"
    if command -v top &> /dev/null; then
        top -bn1 | grep "Cpu(s)" | \
        sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
        awk '{printf "CPU Load: %. 2f%%\n", 100 - $1}'
    else
        echo -e "${RED}Error: 'top' command not found${NC}"
        return 1
    fi
}

# Get total memory usage
get_memory_usage() {
    print_header "Memory Utilization:"
    if command -v free &> /dev/null; then
        free -h | awk '/^Mem:/ {printf "Used: %s / Total: %s (%.2f%%)\n", $3, $2, ($3/$2) * 100.0}'
    else
        echo -e "${RED}Error: 'free' command not found${NC}"
        return 1
    fi
}

# Get total disk usage
get_disk_usage() {
    print_header "Disk Utilization:"
    if command -v df &> /dev/null; then
        df -h --total 2>/dev/null | awk '/^total/ {printf "Used: %s / Total: %s (%s)\n", $3, $2, $5}' || \
        df -h | awk 'END {printf "Used: %s / Total:  %s (%s)\n", $3, $2, $5}'
    else
        echo -e "${RED}Error: 'df' command not found${NC}"
        return 1
    fi
}

# Get top 10 processes by CPU usage
get_top_cpu_processes() {
    print_header "Top 10 Processes by CPU Usage:"
    if command -v ps &> /dev/null; then
        ps -eo pid,ppid,comm,%mem,%cpu --sort=-%cpu | head -11 | \
        awk 'NR==1 {printf "%-8s %-8s %-20s %-8s %-8s\n", $1, $2, $3, $4, $5} 
             NR>1 {printf "%-8s %-8s %-20s %-8s %-8s\n", $1, $2, $3, $4, $5}'
    else
        echo -e "${RED}Error: 'ps' command not found${NC}"
        return 1
    fi
}

# Get top 10 processes by memory usage
get_top_memory_processes() {
    print_header "Top 10 Processes by Memory Usage:"
    if command -v ps &> /dev/null; then
        ps -eo pid,ppid,comm,%mem,%cpu --sort=-%mem | head -11 | \
        awk 'NR==1 {printf "%-8s %-8s %-20s %-8s %-8s\n", $1, $2, $3, $4, $5} 
             NR>1 {printf "%-8s %-8s %-20s %-8s %-8s\n", $1, $2, $3, $4, $5}'
    else
        echo -e "${RED}Error: 'ps' command not found${NC}"
        return 1
    fi
}

# Get load average
get_load_average() {
    print_header "Load Average:"
    if [ -f /proc/loadavg ]; then
        awk '{printf "1 min: %s, 5 min: %s, 15 min: %s\n", $1, $2, $3}' /proc/loadavg
    else
        uptime | awk -F'load average: ' '{print $2}'
    fi
}

# Get network statistics (optional)
get_network_stats() {
    print_header "Network Statistics:"
    if command -v ip &> /dev/null; then
        ip -s link show | awk '/^[0-9]+: / {print $2} /RX: / {getline; rx=$1} /TX:/ {getline; print "Interface:  " iface " | RX: " rx " bytes | TX: " $1 " bytes"; iface=""}'
    elif command -v ifconfig &> /dev/null; then
        echo "Active Network Interfaces:"
        ifconfig | grep -E '^[a-z]|inet ' | head -10
    fi
}

# Additional metrics
get_additional_stats() {
    print_header "Additional System Information:"
    echo "OS Version:  $(uname -s) $(uname -r)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3, $4}')"
    echo "Logged in Users: $(who | wc -l)"
    
    # Show failed login attempts (if available)
    if [ -f /var/log/btmp ] && command -v lastb &> /dev/null; then
        local failed_logins=$(lastb -n 5 2>/dev/null | wc -l)
        if [ "$failed_logins" -gt 1 ]; then
            echo -e "${YELLOW}Recent Failed Login Attempts:  $((failed_logins - 1))${NC}"
        fi
    fi
}

# Main function
main() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Server Performance Statistics${NC}"
    echo -e "${GREEN}Generated:  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    
    get_cpu_usage || echo ""
    echo ""
    
    get_memory_usage || echo ""
    echo ""
    
    get_disk_usage || echo ""
    echo ""
    
    get_load_average || echo ""
    echo ""
    
    get_top_cpu_processes || echo ""
    echo ""
    
    get_top_memory_processes || echo ""
    echo ""
    
    get_additional_stats || echo ""
    echo ""
    
    # Optional: uncomment to include network stats
    # get_network_stats || echo ""
    # echo ""
    
    echo -e "${GREEN}================================${NC}"
}

# Run main function
main "$@"

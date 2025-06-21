#!/bin/bash
#
# Simple Weather API Script
# Description: Calls free weather API and logs the results
# Author: Casey Quinn
# Location: ~/scripts/system/weather-check.sh
#

# Configuration
LOG_FILE="/tmp/weather-check.log"
WEATHER_API="https://wttr.in/Virginia?format=3"  # Free weather API, no key needed

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to get weather data
get_weather() {
    local weather_data=$(curl -s "$WEATHER_API" 2>/dev/null)

    # Check if we got data
    if [ -n "$weather_data" ] && [ "$weather_data" != "curl: command not found" ]; then
        echo "$weather_data"
        return 0
    else
        echo "Weather data unavailable"
        return 1
    fi
}

# Function to get system load for context
get_system_load() {
    local load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | cut -d',' -f1)
    echo "$load"
}

# Main function
main() {
    log_message "=== Starting weather check ==="

    # Get weather data
    local weather=$(get_weather)
    local load=$(get_system_load)

    if [ $? -eq 0 ]; then
        log_message "Weather: $weather | System Load: $load"
        echo "✅ Weather check completed: $weather"
    else
        log_message "ERROR: Failed to get weather data | System Load: $load"
        echo "❌ Weather check failed"
    fi

    log_message "=== Weather check completed ==="
}

# Run the script
main "$@"
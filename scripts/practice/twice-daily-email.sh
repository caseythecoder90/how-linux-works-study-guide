#!/bin/bash
#
# Enhanced Daily Inspiration Script - Morning and Evening Versions
# Description: Sends different inspiration content based on time of day
# Author: Casey Quinn
# Location: ~/scripts/daily/daily-inspiration-enhanced.sh
#

# Configuration
API_KEY="fill with env var"  # Replace with your actual API key
EMAIL_TO="fill with env var"  # Replace with actual emails
LOG_FILE="/tmp/daily-inspiration.log"

# Function to determine time of day and content type
get_time_context() {
    local hour=$(date '+%H')
    local time_of_day=""
    local greeting=""
    local time_emoji=""
    local content_focus=""

    if (( hour >= 5 && hour < 12 )); then
        time_of_day="morning"
        greeting="Good morning"
        time_emoji="🌅"
        content_focus="starting the day with energy and purpose"
    elif (( hour >= 12 && hour < 17 )); then
        time_of_day="afternoon"
        greeting="Good afternoon"
        time_emoji="☀️"
        content_focus="maintaining momentum and staying positive"
    elif (( hour >= 17 && hour < 22 )); then
        time_of_day="evening"
        greeting="Good evening"
        time_emoji="🌆"
        content_focus="reflecting on the day and preparing for rest"
    else
        time_of_day="night"
        greeting="Good evening"
        time_emoji="🌙"
        content_focus="winding down and finding peace"
    fi

    echo "$time_of_day|$greeting|$time_emoji|$content_focus"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to get system context
get_system_context() {
    local day_of_week=$(date '+%A')
    local current_date=$(date '+%B %d, %Y')
    local current_time=$(date '+%I:%M %p')
    echo "Today is $day_of_week, $current_date at $current_time"
}

# Function to get device/system information
get_device_info() {
    local hostname=$(hostname)
    local uptime_info=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    local memory_usage=$(free -h | awk 'NR==2{printf "%s/%s (%.1f%%)", $3,$2,$3*100/$2}')
    local disk_usage=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')

    cat << EOF
<div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #007bff;">
    <h4 style="color: #495057; margin: 0 0 10px 0; font-size: 16px;">💻 System Status</h4>
    <p style="margin: 5px 0; color: #6c757d; font-size: 14px;">
        <strong>Host:</strong> $hostname &nbsp;|&nbsp; <strong>Uptime:</strong> $uptime_info
    </p>
    <p style="margin: 5px 0; color: #6c757d; font-size: 14px;">
        <strong>Memory:</strong> $memory_usage &nbsp;|&nbsp; <strong>Disk:</strong> $disk_usage
    </p>
    <p style="margin: 5px 0; color: #6c757d; font-size: 14px;">
        <strong>Load Average:</strong> $load_avg
    </p>
</div>
EOF
}

# Function to call Claude API with time-specific prompts
call_claude_api() {
    local system_context="$1"
    local time_context="$2"
    local content_focus="$3"

    # Create time-specific prompt
    local prompt="Please provide a ${time_context} inspiration message for a couple, focused on ${content_focus}. Include:

1. An uplifting motivational quote appropriate for ${time_context}
2. A brief inspirational message (2-3 sentences) about ${content_focus}
3. A Bible verse with reference that relates to the ${time_context} theme
4. A practical tip for ${content_focus} as a couple

Context: $system_context

Format this for an HTML email. Use simple formatting - just line breaks and maybe some emphasis. Keep it warm and encouraging, tailored for ${time_context}."

    # API request payload
    local json_payload=$(jq -n \
        --arg model "claude-3-haiku-20240307" \
        --arg content "$prompt" \
        '{
            "model": $model,
            "max_tokens": 400,
            "messages": [
                {
                    "role": "user",
                    "content": $content
                }
            ]
        }')

    # Make API call
    local response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$json_payload")

    # Extract content from response using jq
    echo "$response" | jq -r '.content[0].text' 2>/dev/null
}

# Function to create beautiful HTML email with time-specific styling
create_html_email() {
    local inspiration_content="$1"
    local device_info="$2"
    local greeting="$3"
    local time_emoji="$4"
    local time_of_day="$5"
    local current_date=$(date '+%A, %B %d, %Y')
    local current_time=$(date '+%I:%M %p')

    # Time-specific gradient colors
    local gradient=""
    case $time_of_day in
        "morning")
            gradient="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"
            ;;
        "afternoon")
            gradient="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);"
            ;;
        "evening")
            gradient="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);"
            ;;
        "night")
            gradient="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);"
            ;;
    esac

    cat << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$greeting Inspiration</title>
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; background-color: #f4f4f4;">

    <!-- Header -->
    <div style="$gradient color: white; padding: 30px 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="margin: 0; font-size: 28px; font-weight: 300;">$time_emoji ${greeting^} Inspiration</h1>
        <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">$current_date • $current_time</p>
    </div>

    <!-- Main Content -->
    <div style="background: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">

        <!-- Greeting -->
        <div style="text-align: center; margin-bottom: 25px;">
            <h2 style="color: #495057; font-size: 22px; margin: 0;">$greeting, beautiful people! $time_emoji</h2>
            <p style="color: #6c757d; font-size: 16px; margin: 10px 0;">Here's your $time_of_day dose of inspiration</p>
        </div>

        <!-- Inspiration Content -->
        <div style="background: #fff; padding: 20px; border-radius: 8px; margin: 20px 0; border: 1px solid #e9ecef;">
            $inspiration_content
        </div>

        <!-- System Info -->
        $device_info

        <!-- Footer Message -->
        <div style="text-align: center; margin-top: 25px; padding-top: 20px; border-top: 1px solid #e9ecef;">
            <p style="color: #28a745; font-size: 18px; margin: 10px 0;">Have an amazing $time_of_day together! 💕</p>
            <p style="color: #6c757d; font-size: 14px; margin: 5px 0;">
                Sent with love from Casey's VM ❤️<br>
                Generated on $current_date at $current_time
            </p>
        </div>

    </div>

    <!-- Fun Footer -->
    <div style="text-align: center; margin-top: 20px; padding: 15px;">
        <p style="color: #6c757d; font-size: 12px; margin: 0;">
            🤖 Powered by Linux automation, Claude AI, and lots of caffeine ☕
        </p>
    </div>

</body>
</html>
EOF
}

# Function to send HTML email
send_html_email() {
    local subject="$1"
    local html_body="$2"

    # Create email with proper HTML headers
    local email_content=$(cat << EOF
To: $EMAIL_TO
From: "Daily Inspiration Bot" <caseythecoder90@gmail.com>
Subject: $subject
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

$html_body
EOF
)

    # Send email using ssmtp
    echo "$email_content" | ssmtp $EMAIL_TO
}

# Main function
main() {
    log_message "=== Starting enhanced daily inspiration script ==="

    # Check if API key is configured
    if [[ "$API_KEY" == "your-actual-api-key-here" ]]; then
        log_message "ERROR: API key not configured"
        echo "❌ Please set your Anthropic API key in the script"
        exit 1
    fi

    # Get time context
    local time_info=$(get_time_context)
    IFS='|' read -r time_of_day greeting time_emoji content_focus <<< "$time_info"

    # Get system context
    local system_context=$(get_system_context)
    local device_info=$(get_device_info)

    log_message "Time context: $time_of_day - $greeting"
    log_message "System context: $system_context"

    # Call Claude API with time-specific context
    log_message "Calling Claude API for $time_of_day inspiration content"
    local inspiration_content=$(call_claude_api "$system_context" "$time_of_day" "$content_focus")

    # Check if API call was successful and format content
    if [[ -z "$inspiration_content" ]] || [[ "$inspiration_content" == "null" ]] || [[ "$inspiration_content" == *"error"* ]]; then
        log_message "API call failed, using fallback content"
        inspiration_content="<p>$greeting! Today is a gift - make it count together! 💕</p>"
    else
        # Convert Claude's response to HTML format
        inspiration_content=$(echo "$inspiration_content" | sed 's/$/\<br\>/g' | sed 's/\*\*\(.*\)\*\*/\<strong\>\1\<\/strong\>/g')
    fi

    # Create beautiful HTML email
    local html_body=$(create_html_email "$inspiration_content" "$device_info" "$greeting" "$time_emoji" "$time_of_day")

    # Prepare email subject
    local email_subject="$time_emoji $greeting Inspiration - $(date '+%A, %B %d')"

    # Send email
    log_message "Sending $time_of_day HTML email to: $EMAIL_TO"
    if send_html_email "$email_subject" "$html_body"; then
        log_message "✅ Beautiful $time_of_day HTML email sent successfully"
        echo "✅ $greeting inspiration email sent with beautiful formatting!"
    else
        log_message "❌ Failed to send email"
        echo "❌ Failed to send email - check log: $LOG_FILE"
    fi

    log_message "=== Enhanced daily inspiration script completed ==="
}

# Run the main function
main "$@"
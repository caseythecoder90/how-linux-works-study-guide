 #!/bin/bash
 # File Sharing Security Audit Script
 # File: examples/monitoring/security-audit.sh

 set -euo pipefail

 # Configuration
 SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 AUDIT_REPORT_DIR="/var/log/security-audits"
 REPORT_FILE="$AUDIT_REPORT_DIR/file-sharing-audit-$(date +%Y%m%d-%H%M%S).html"
 LOG_FILE="$AUDIT_REPORT_DIR/audit-$(date +%Y%m%d-%H%M%S).log"

 # Compliance frameworks
 COMPLIANCE_FRAMEWORKS=("GDPR" "SOX" "HIPAA" "PCI-DSS" "ISO27001")

 # Critical security thresholds
 MAX_FAILED_LOGINS=10
 MAX_WORLD_WRITABLE_FILES=5
 MAX_SUID_FILES=50
 PASSWORD_MIN_AGE=1
 PASSWORD_MAX_AGE=90

 # Colors for output
 RED='\033[0;31m'
 GREEN='\033[0;32m'
 YELLOW='\033[1;33m'
 BLUE='\033[0;34m'
 CYAN='\033[0;36m'
 NC='\033[0m'

 # Counters for findings
 CRITICAL_FINDINGS=0
 HIGH_FINDINGS=0
 MEDIUM_FINDINGS=0
 LOW_FINDINGS=0
 INFO_FINDINGS=0

 log() {
     local level=$1
     shift
     local message="$*"
     local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

     echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"

     case $level in
         "CRITICAL")
             echo -e "${RED}[CRITICAL] $message${NC}" >&2
             ((CRITICAL_FINDINGS++))
             ;;
         "HIGH")
             echo -e "${RED}[HIGH] $message${NC}" >&2
             ((HIGH_FINDINGS++))
             ;;
         "MEDIUM")
             echo -e "${YELLOW}[MEDIUM] $message${NC}" >&2
             ((MEDIUM_FINDINGS++))
             ;;
         "LOW")
             echo -e "${BLUE}[LOW] $message${NC}"
             ((LOW_FINDINGS++))
             ;;
         "INFO")
             echo -e "${GREEN}[INFO] $message${NC}"
             ((INFO_FINDINGS++))
             ;;
         "PASS")
             echo -e "${GREEN}[PASS] $message${NC}"
             ;;
         "ERROR")
             echo -e "${RED}[ERROR] $message${NC}" >&2
             ;;
     esac
 }

 show_usage() {
     cat << EOF
 File Sharing Security Audit Script

 Usage: $0 [OPTIONS] [audit-type]

 Audit Types:
     full                    Complete security audit (de
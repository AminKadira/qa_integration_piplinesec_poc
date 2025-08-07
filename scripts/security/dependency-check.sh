#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:-./app}"
CONFIG_FILE="${2:-./config/security.json}"

# Lecture configuration
CVSS_THRESHOLD=$(jq -r '.owasp.dependencyCheck.failOnCVSS' "$CONFIG_FILE")
SUPPRESSION_FILE=$(jq -r '.owasp.dependencyCheck.suppressionFile' "$CONFIG_FILE")

echo "SECURITY: Starting OWASP Dependency Check..."
echo "Project: $PROJECT_DIR"
echo "CVSS Threshold: $CVSS_THRESHOLD"

cd "$PROJECT_DIR"

# Validation pré-requis
command -v dependency-check.sh >/dev/null 2>&1 || {
    echo "ERROR: OWASP Dependency Check not installed"
    exit 1
}

# Exécution scan
dependency-check.sh \
    --project "SPF-Invoice-Service" \
    --scan . \
    --format ALL \
    --out dependency-check-report \
    --data "${DEPENDENCY_CHECK_DATA}" \
    --failOnCVSS "$CVSS_THRESHOLD" \
    --suppression "../$SUPPRESSION_FILE" \
    --enableRetired \
    --enableExperimental

echo "SUCCESS: Dependency scan completed"

# Validation résultats
VULNERABILITIES=$(jq '.dependencies | map(select(.vulnerabilities | length > 0)) | length' dependency-check-report/dependency-check-report.json)
echo "Vulnerabilities found: $VULNERABILITIES"

if [ "$VULNERABILITIES" -gt 0 ]; then
    echo "WARNING: Security vulnerabilities detected"
    jq '.dependencies[] | select(.vulnerabilities | length > 0) | {fileName, vulnerabilities: .vulnerabilities | length}' dependency-check-report/dependency-check-report.json
fi
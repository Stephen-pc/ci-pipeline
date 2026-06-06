#!/bin/bash
# validate-config.sh — Validate CI/CD configuration files
# Usage: bash scripts/validate-config.sh <file>
#
# Checks:
# 1. YAML syntax validity
# 2. Required fields present
# 3. Security best practices
# 4. Common mistakes

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_error() { echo -e "${RED}ERROR:${NC} $1"; ((ERRORS++)); }
log_warn() { echo -e "${YELLOW}WARN:${NC} $1"; ((WARNINGS++)); }
log_ok() { echo -e "${GREEN}OK:${NC} $1"; }

# Check if file exists
if [ $# -eq 0 ]; then
    echo "Usage: bash validate-config.sh <file>"
    echo ""
    echo "Validates GitHub Actions or GitLab CI configuration files."
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    log_error "File not found: $FILE"
    exit 1
fi

echo "Validating: $FILE"
echo "================================"

# 1. Check YAML syntax
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('$FILE'))" 2>/dev/null; then
        log_ok "YAML syntax is valid"
    else
        log_error "Invalid YAML syntax"
    fi
elif command -v python &> /dev/null; then
    if python -c "import yaml; yaml.safe_load(open('$FILE'))" 2>/dev/null; then
        log_ok "YAML syntax is valid"
    else
        log_error "Invalid YAML syntax"
    fi
else
    log_warn "Python not found, skipping YAML validation"
fi

# 2. Detect platform
if [[ "$FILE" == *".github/workflows/"* ]] || [[ "$FILE" == *".yml" ]] && grep -q "on:" "$FILE" 2>/dev/null; then
    PLATFORM="github"
elif grep -q "stages:" "$FILE" 2>/dev/null || grep -q "script:" "$FILE" 2>/dev/null; then
    PLATFORM="gitlab"
else
    PLATFORM="unknown"
fi

echo "Detected platform: $PLATFORM"
echo ""

# 3. Security checks
echo "--- Security Checks ---"

# Check for unpinned actions (GitHub Actions)
if [ "$PLATFORM" = "github" ]; then
    # Check for @v1, @v2, @v3, @v4 tags instead of SHA
    UNPINNED=$(grep -n 'uses:.*@v[0-9]' "$FILE" 2>/dev/null | grep -v '#' || true)
    if [ -n "$UNPINNED" ]; then
        log_warn "Unpinned action versions found (use SHA instead of tag):"
        echo "$UNPINNED" | sed 's/^/  /'
    else
        log_ok "All actions pinned to SHA"
    fi

    # Check for hardcoded secrets
    if grep -q 'password:' "$FILE" 2>/dev/null && ! grep -q 'secrets\.' "$FILE" 2>/dev/null; then
        log_warn "Possible hardcoded password detected"
    fi

    # Check for permissions
    if grep -q 'permissions:' "$FILE" 2>/dev/null; then
        log_ok "Permissions block found"
    else
        log_warn "No permissions block — consider adding least-privilege permissions"
    fi
fi

# 4. Best practices checks
echo ""
echo "--- Best Practices ---"

# Check for timeout
if grep -q 'timeout-minutes' "$FILE" 2>/dev/null; then
    log_ok "Timeout configured"
else
    log_warn "No timeout-minutes set — hung jobs could run indefinitely"
fi

# Check for concurrency
if grep -q 'concurrency:' "$FILE" 2>/dev/null; then
    log_ok "Concurrency control configured"
else
    log_warn "No concurrency group — redundant runs may waste resources"
fi

# Check for caching
if grep -q 'cache' "$FILE" 2>/dev/null; then
    log_ok "Caching configured"
else
    log_warn "No caching detected — builds may be slower than necessary"
fi

# Check for matrix builds (multi-version testing)
if grep -q 'matrix:' "$FILE" 2>/dev/null; then
    log_ok "Matrix build configured"
fi

# 5. Structure checks (GitHub Actions)
if [ "$PLATFORM" = "github" ]; then
    echo ""
    echo "--- Structure Checks ---"

    if grep -q 'on:' "$FILE" 2>/dev/null; then
        log_ok "Trigger (on:) defined"
    else
        log_error "No trigger (on:) block found"
    fi

    if grep -q 'jobs:' "$FILE" 2>/dev/null; then
        log_ok "Jobs block found"
    else
        log_error "No jobs: block found"
    fi

    if grep -q 'runs-on:' "$FILE" 2>/dev/null; then
        log_ok "Runner (runs-on:) specified"
    else
        log_warn "No runs-on: found — jobs need a runner"
    fi
fi

# 6. GitLab CI checks
if [ "$PLATFORM" = "gitlab" ]; then
    echo ""
    echo "--- Structure Checks ---"

    if grep -q 'stages:' "$FILE" 2>/dev/null; then
        log_ok "Stages defined"
    else
        log_warn "No stages block — using default stages"
    fi

    if grep -q 'script:' "$FILE" 2>/dev/null; then
        log_ok "Script blocks found"
    else
        log_error "No script: blocks found"
    fi
fi

# Summary
echo ""
echo "================================"
echo "Results: $ERRORS errors, $WARNINGS warnings"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Validation failed${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Validation passed with warnings${NC}"
    exit 0
else
    echo -e "${GREEN}Validation passed${NC}"
    exit 0
fi

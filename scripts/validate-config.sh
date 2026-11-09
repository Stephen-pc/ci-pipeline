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

log_error() { echo -e "${RED}ERROR:${NC} $1"; ERRORS=$((ERRORS + 1)); }
# 注意：这里不能用 ((WARNINGS++))。算术表达式的退出码是「自增前的值」，
# 当 WARNINGS 为 0 时 ((WARNINGS++)) 返回 1，配合脚本顶部的 set -e 会直接
# 终止整个校验——表现为：出现第一条警告就静默退出，Summary 永远打不出来，
# 退出码 1 而错误数是 0。曾经让全部 GitLab 模板都「校验失败」。
log_warn() { echo -e "${YELLOW}WARN:${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
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
# 三件事必须分开，否则会给出误导性的结论：
#   a) 找不到带 PyYAML 的解释器 → 无法校验，跳过（不是错误）
#   b) 文件路径通过 argv 传给 Python，不要拼进代码字符串。
#      拼接会让「路径含空格 / 引号」和「Git Bash 的 /tmp/... 交给 Windows 版
#      Python」这两种情况统统表现成语法错误——用户会被告知自己合法的配置有问题。
#   c) 真正的语法错误才报 ERROR。
yaml_check() {
    # 返回 0=合法, 1=语法错误, 2=该解释器没有 PyYAML
    local py="$1" f="$2"
    "$py" -c 'import yaml' >/dev/null 2>&1 || return 2
    "$py" -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding="utf-8"))' "$f" >/dev/null 2>&1
}

PYTHON_BIN=""
for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import yaml' >/dev/null 2>&1; then
        PYTHON_BIN="$cand"
        break
    fi
done

if [ -n "$PYTHON_BIN" ]; then
    yaml_rc=0
    yaml_check "$PYTHON_BIN" "$FILE" || yaml_rc=$?
    case "$yaml_rc" in
        0) log_ok "YAML syntax is valid" ;;
        1) log_error "Invalid YAML syntax" ;;
        *) log_warn "PyYAML unavailable, skipping YAML syntax validation" ;;
    esac
else
    log_warn "No Python with PyYAML found, skipping YAML validation (pip install pyyaml)"
fi

# 2. Detect platform
# 原来的写法是：
#   [[ "$FILE" == *".github/workflows/"* ]] || [[ "$FILE" == *".yml" ]] && grep -q "on:" "$FILE"
# 而 && 的优先级高于 ||，等价于 A || (B && C)：任何含 "on:" 的 .yml 都会被判成
# github——包括 GitLab 模板（脚本里随便一个 "on:" 就中招）。结果拿 GitHub 的规则
# 去评判 GitLab 文件，报出「缺少 permissions block」这种在该平台无意义的结论。
detect_platform() {
    local f="$1"
    case "$f" in
        *.gitlab-ci.yml|*/gitlab-ci/*) echo "gitlab"; return ;;
        */.github/workflows/*|*.github/workflows/*) echo "github"; return ;;
    esac
    # 路径不可靠时看内容。script: 是 GitLab 的必需字段，GitHub 没有；
    # 反过来 runs-on: / jobs: 是 GitHub 的特征。都用行首锚定，避免匹配到
    # 脚本正文里的同名片段。
    if grep -qE '^[[:space:]]*script:' "$f" 2>/dev/null \
        && ! grep -qE '^[[:space:]]*(jobs|runs-on):' "$f" 2>/dev/null; then
        echo "gitlab"; return
    fi
    if grep -qE '^on:' "$f" 2>/dev/null \
        || grep -qE '^[[:space:]]*runs-on:' "$f" 2>/dev/null; then
        echo "github"; return
    fi
    echo "unknown"
}

PLATFORM=$(detect_platform "$FILE")

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
# 这些键是平台专属的：GitHub 用 timeout-minutes / concurrency / matrix，
# GitLab 用 timeout / resource_group / parallel。拿 GitHub 的键去查 GitLab 文件，
# 会稳定报出三条「没配超时 / 没配并发 / 没配矩阵」的假警告——用户照着改还得
# 现找一个不存在的字段。
echo ""
echo "--- Best Practices ---"

if [ "$PLATFORM" = "unknown" ]; then
    echo "Skip: platform unknown, not judging best practices"
else
    if [ "$PLATFORM" = "github" ]; then
        TIMEOUT_KEY='timeout-minutes'; TIMEOUT_NAME='timeout-minutes'
        CONC_KEY='concurrency:';       CONC_NAME='concurrency group'
        PARA_KEY='matrix:';            PARA_NAME='matrix build'
    else
        TIMEOUT_KEY='timeout:';        TIMEOUT_NAME='timeout'
        CONC_KEY='resource_group:';    CONC_NAME='resource_group'
        PARA_KEY='parallel:';          PARA_NAME='parallel'
    fi

    if grep -q "$TIMEOUT_KEY" "$FILE" 2>/dev/null; then
        log_ok "Timeout configured ($TIMEOUT_NAME)"
    else
        log_warn "No $TIMEOUT_NAME set — hung jobs could run indefinitely"
    fi

    if grep -q "$CONC_KEY" "$FILE" 2>/dev/null; then
        log_ok "Concurrency control configured ($CONC_NAME)"
    else
        log_warn "No $CONC_NAME — redundant runs may waste resources"
    fi

    # cache 两个平台都有，不必分开
    if grep -q 'cache' "$FILE" 2>/dev/null; then
        log_ok "Caching configured"
    else
        log_warn "No caching detected — builds may be slower than necessary"
    fi

    if grep -q "$PARA_KEY" "$FILE" 2>/dev/null; then
        log_ok "$PARA_NAME configured"
    fi
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

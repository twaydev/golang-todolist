#!/bin/bash
# MCP Integration Pre-flight Check
# This script verifies that all required MCP servers are configured and working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}             MCP Integration Pre-flight Check                   ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Track overall status
ALL_PASSED=true

# Function to check environment variable
check_env() {
    local var_name=$1
    local description=$2
    if [[ -z "${!var_name}" ]]; then
        echo -e "  ${RED}✗${NC} ${var_name} - Not set"
        return 1
    else
        echo -e "  ${GREEN}✓${NC} ${var_name} - Set"
        return 0
    fi
}

# Function to print section header
section() {
    echo -e "\n${YELLOW}▸ $1${NC}"
    echo -e "  ─────────────────────────────────────────"
}

# ─────────────────────────────────────────────────────────────────────────────
# Environment Variables Check
# ─────────────────────────────────────────────────────────────────────────────
section "Environment Variables"

LINEAR_OK=true
SUPABASE_OK=true
RAILWAY_OK=true

echo -e "\n  ${BLUE}Linear:${NC}"
check_env "LINEAR_API_KEY" "Linear API key" || LINEAR_OK=false

echo -e "\n  ${BLUE}Supabase:${NC}"
check_env "SUPABASE_URL" "Supabase project URL" || SUPABASE_OK=false
check_env "SUPABASE_KEY" "Supabase service key" || SUPABASE_OK=false

echo -e "\n  ${BLUE}Railway:${NC}"
check_env "RAILWAY_TOKEN" "Railway API token" || RAILWAY_OK=false

# ─────────────────────────────────────────────────────────────────────────────
# MCP Server Availability
# ─────────────────────────────────────────────────────────────────────────────
section "MCP Server Status"

echo -e "\n  ${BLUE}Note:${NC} MCP servers are invoked by the AI agent, not CLI commands."
echo -e "  The following are the MCP functions that will be used:"
echo ""
echo -e "  ${YELLOW}Linear MCP:${NC}"
echo -e "    • linear_get_teams        - List teams/workspaces"
echo -e "    • linear_get_labels       - List issue labels"
echo -e "    • linear_create_issue     - Create new issues"
echo -e "    • linear_update_issue     - Update issue status"
echo -e "    • linear_add_comment      - Add comments to issues"
echo ""
echo -e "  ${YELLOW}Supabase MCP:${NC}"
echo -e "    • supabase_list_projects  - List Supabase projects"
echo -e "    • supabase_get_project    - Get project details"
echo -e "    • supabase_list_tables    - List database tables"
echo -e "    • supabase_execute_sql    - Execute SQL queries"
echo ""
echo -e "  ${YELLOW}Railway MCP:${NC}"
echo -e "    • railway_list_projects   - List Railway projects"
echo -e "    • railway_get_project     - Get project info"
echo -e "    • railway_deploy          - Deploy service"
echo -e "    • railway_set_variable    - Set env variables"
echo -e "    • railway_get_service_url - Get deployment URL"

# ─────────────────────────────────────────────────────────────────────────────
# Go Environment Check
# ─────────────────────────────────────────────────────────────────────────────
section "Go Environment"

if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo -e "  ${GREEN}✓${NC} Go installed: ${GO_VERSION}"

    # Check Go version is 1.22+
    GO_MINOR=$(echo $GO_VERSION | sed 's/go1\.//' | cut -d. -f1)
    if [[ "$GO_MINOR" -ge 22 ]]; then
        echo -e "  ${GREEN}✓${NC} Go version meets requirement (1.22+)"
    else
        echo -e "  ${YELLOW}⚠${NC} Go version should be 1.22+ (current: ${GO_VERSION})"
    fi
else
    echo -e "  ${RED}✗${NC} Go not installed"
    ALL_PASSED=false
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                          Summary                               ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$LINEAR_OK" == true ]]; then
    echo -e "  Linear:   ${GREEN}✓ Ready${NC}"
else
    echo -e "  Linear:   ${RED}✗ Missing credentials${NC}"
    ALL_PASSED=false
fi

if [[ "$SUPABASE_OK" == true ]]; then
    echo -e "  Supabase: ${GREEN}✓ Ready${NC}"
else
    echo -e "  Supabase: ${RED}✗ Missing credentials${NC}"
    ALL_PASSED=false
fi

if [[ "$RAILWAY_OK" == true ]]; then
    echo -e "  Railway:  ${GREEN}✓ Ready${NC}"
else
    echo -e "  Railway:  ${RED}✗ Missing credentials${NC}"
    ALL_PASSED=false
fi

echo ""

if [[ "$ALL_PASSED" == true ]]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  All checks passed! Ready to proceed with orchestrator.        ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Some checks failed. Please configure missing credentials.     ${NC}"
    echo -e "${YELLOW}                                                                 ${NC}"
    echo -e "${YELLOW}  Set environment variables or add them to .env file:           ${NC}"
    echo -e "${YELLOW}    export LINEAR_API_KEY=lin_api_xxxxx                          ${NC}"
    echo -e "${YELLOW}    export SUPABASE_URL=https://xxxxx.supabase.co                ${NC}"
    echo -e "${YELLOW}    export SUPABASE_KEY=eyJxxxxx                                 ${NC}"
    echo -e "${YELLOW}    export RAILWAY_TOKEN=xxxxx                                   ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
fi

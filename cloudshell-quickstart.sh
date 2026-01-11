#!/bin/bash
################################################################################
# Cloud Shell Quick Start - Tenant Reader
# Run this first to understand your Azure access
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║         Azure Cloud Shell - Quick Access Check            ║${NC}"
echo -e "${CYAN}║              Tenant Reader Edition                         ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if logged in
if ! az account show &>/dev/null; then
    echo -e "${RED}✗ Not logged in to Azure${NC}"
    echo -e "${YELLOW}Please run: az login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Logged in to Azure${NC}\n"

# Get basic info
TENANT_ID=$(az account show --query tenantId -o tsv)
USER=$(az account show --query user.name -o tsv)
SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}YOUR AZURE CONTEXT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "User:               ${CYAN}$USER${NC}"
echo -e "Tenant ID:          ${CYAN}$TENANT_ID${NC}"
echo -e "Current Sub:        ${CYAN}$SUB_NAME${NC}"
echo -e "Subscription ID:    ${CYAN}$SUB_ID${NC}"
echo ""

# Count subscriptions
TOTAL_SUBS=$(az account list --query 'length([])' -o tsv)
echo -e "Total Subscriptions: ${CYAN}$TOTAL_SUBS${NC}"
echo ""

# Check access levels
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ACCESS LEVEL CHECKS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check Azure AD access
echo -n "Azure AD Users:        "
if az ad user list --query '[0]' &>/dev/null; then
    USER_COUNT=$(az ad user list --query 'length([])' -o tsv)
    echo -e "${GREEN}✓ Can access ($USER_COUNT users)${NC}"
    HAS_AD_ACCESS=true
else
    echo -e "${RED}✗ No access${NC}"
    HAS_AD_ACCESS=false
fi

echo -n "Azure AD Groups:       "
if az ad group list --query '[0]' &>/dev/null; then
    GROUP_COUNT=$(az ad group list --query 'length([])' -o tsv)
    echo -e "${GREEN}✓ Can access ($GROUP_COUNT groups)${NC}"
else
    echo -e "${RED}✗ No access${NC}"
fi

echo -n "Subscription Resources:"
if az resource list --query '[0]' &>/dev/null; then
    RES_COUNT=$(az resource list --query 'length([])' -o tsv)
    echo -e "${GREEN}✓ Can access ($RES_COUNT resources)${NC}"
    HAS_SUB_ACCESS=true
else
    echo -e "${RED}✗ No access${NC}"
    HAS_SUB_ACCESS=false
fi

echo -n "Resource Groups:       "
if az group list --query '[0]' &>/dev/null; then
    RG_COUNT=$(az group list --query 'length([])' -o tsv)
    echo -e "${GREEN}✓ Can access ($RG_COUNT groups)${NC}"
else
    echo -e "${RED}✗ No access${NC}"
fi

echo -n "Cost Data:             "
if az costmanagement query --type "Usage" --timeframe "MonthToDate" --scope "/subscriptions/$SUB_ID" &>/dev/null 2>&1; then
    echo -e "${GREEN}✓ Can access${NC}"
    HAS_COST_ACCESS=true
else
    echo -e "${RED}✗ No access (need Cost Management Reader)${NC}"
    HAS_COST_ACCESS=false
fi

echo ""

# Your roles
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}YOUR ROLE ASSIGNMENTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
az role assignment list --assignee "$USER" --all --query "[].{Role:roleDefinitionName, Scope:scope}" -o table 2>/dev/null || echo "Unable to retrieve roles"
echo ""

# Determine access level
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ACCESS SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$HAS_AD_ACCESS" = true ] && [ "$HAS_SUB_ACCESS" = false ]; then
    echo -e "${YELLOW}Current Access Level: Tenant Reader${NC}"
    echo ""
    echo "You can access:"
    echo "  ✓ Azure AD users and groups"
    echo "  ✓ Subscription list"
    echo "  ✓ Your own role assignments"
    echo ""
    echo "You CANNOT access:"
    echo "  ✗ Subscription resources (VMs, AKS, Storage, etc.)"
    echo "  ✗ Cost and billing data"
    echo "  ✗ Security recommendations"
    echo ""
    echo -e "${CYAN}Recommended Next Steps:${NC}"
    echo "  1. Request 'Reader' role on subscription(s) for resource access"
    echo "  2. Request 'Cost Management Reader' for cost data"
    echo "  3. Run: ./cloudshell-tenant-inventory.sh for detailed tenant audit"
elif [ "$HAS_SUB_ACCESS" = true ]; then
    echo -e "${GREEN}Current Access Level: Subscription Reader (or higher)${NC}"
    echo ""
    echo "You have good access! You can:"
    echo "  ✓ View all resources in subscription"
    echo "  ✓ Access Azure AD information"
    echo "  ✓ Generate infrastructure reports"
    echo ""
    if [ "$HAS_COST_ACCESS" = false ]; then
        echo -e "${YELLOW}Note: No cost data access${NC}"
        echo "  Request 'Cost Management Reader' for cost analysis"
        echo ""
    fi
    echo -e "${CYAN}Recommended Next Steps:${NC}"
    echo "  1. Run: ./azure-resource-inventory.sh for full infrastructure audit"
    echo "  2. Run: ./azure-security-compliance-audit.sh for security scan"
    echo "  3. Review: azure-cost-optimization-report.md for cost savings"
else
    echo -e "${RED}Limited Access Detected${NC}"
    echo ""
    echo "You have minimal Azure access."
    echo "Contact your Azure administrator for appropriate roles."
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}AVAILABLE SCRIPTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "For Tenant Reader access:"
echo "  ${CYAN}./cloudshell-tenant-inventory.sh${NC}"
echo "    → Azure AD users, groups, and tenant-level data"
echo ""
echo "For Subscription Reader access:"
echo "  ${CYAN}./azure-resource-inventory.sh${NC}"
echo "    → Complete infrastructure inventory"
echo ""
echo "  ${CYAN}./azure-security-compliance-audit.sh${NC}"
echo "    → Security posture assessment"
echo ""
echo "Documentation:"
echo "  ${CYAN}cat CLOUDSHELL-TENANT-READER-GUIDE.md${NC}"
echo "    → Complete guide for your access level"
echo ""
echo "  ${CYAN}cat QUICK-REFERENCE.md${NC}"
echo "    → One-page command reference"
echo ""

# List all subscriptions
if [ "$TOTAL_SUBS" -gt 1 ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}ALL SUBSCRIPTIONS IN TENANT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    az account list --query "[].{Name:name, State:state, ID:id}" -o table
    echo ""
    echo "To switch subscription:"
    echo "  ${CYAN}az account set --subscription \"SUBSCRIPTION_NAME\"${NC}"
    echo ""
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ready to explore your Azure environment!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

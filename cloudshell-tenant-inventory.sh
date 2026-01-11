#!/bin/bash
################################################################################
# Azure Tenant Inventory for Cloud Shell (Tenant Reader Access)
# Optimized for: Azure Cloud Shell + Tenant Reader role
# Date: January 11, 2026
################################################################################

set -e

# Colors for Cloud Shell
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Output directory
OUTPUT_DIR="tenant-inventory-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Azure Tenant Inventory Tool            ║${NC}"
echo -e "${GREEN}║  Optimized for Cloud Shell               ║${NC}"
echo -e "${GREEN}║  Access Level: Tenant Reader             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo -e "${CYAN}Output Directory: $OUTPUT_DIR${NC}\n"

################################################################################
# 1. Tenant & Account Information
################################################################################
echo -e "${YELLOW}[1/8] Collecting Tenant Information...${NC}"

TENANT_ID=$(az account show --query tenantId -o tsv)
CURRENT_USER=$(az account show --query user.name -o tsv)

cat > "$OUTPUT_DIR/01-tenant-info.txt" << EOF
=== Azure Tenant Information ===
Generated: $(date)
Tenant ID: $TENANT_ID
Current User: $CURRENT_USER
Access Level: Tenant Reader

=== Current Context ===
EOF

az account show >> "$OUTPUT_DIR/01-tenant-info.txt" 2>&1

echo -e "\n=== All Subscriptions in Tenant ===" >> "$OUTPUT_DIR/01-tenant-info.txt"
az account list --output table >> "$OUTPUT_DIR/01-tenant-info.txt" 2>&1

echo -e "\n=== Subscription Summary ===" >> "$OUTPUT_DIR/01-tenant-info.txt"
echo "Total Subscriptions: $(az account list --query 'length([])' -o tsv)" >> "$OUTPUT_DIR/01-tenant-info.txt"
echo "Enabled: $(az account list --query "[?state=='Enabled'] | length([])" -o tsv)" >> "$OUTPUT_DIR/01-tenant-info.txt"
echo "Disabled: $(az account list --query "[?state=='Disabled'] | length([])" -o tsv)" >> "$OUTPUT_DIR/01-tenant-info.txt"

################################################################################
# 2. Azure AD Users
################################################################################
echo -e "${YELLOW}[2/8] Collecting Azure AD Users...${NC}"

echo "=== Azure AD Users ===" > "$OUTPUT_DIR/02-azure-ad-users.txt"

if az ad user list --output table >> "$OUTPUT_DIR/02-azure-ad-users.txt" 2>&1; then
    USER_COUNT=$(az ad user list --query 'length([])' -o tsv)
    echo -e "\n=== User Statistics ===" >> "$OUTPUT_DIR/02-azure-ad-users.txt"
    echo "Total Users: $USER_COUNT" >> "$OUTPUT_DIR/02-azure-ad-users.txt"

    # Guest users
    GUEST_COUNT=$(az ad user list --query "[?userType=='Guest'] | length([])" -o tsv)
    echo "Guest Users: $GUEST_COUNT" >> "$OUTPUT_DIR/02-azure-ad-users.txt"

    # Member users
    MEMBER_COUNT=$(az ad user list --query "[?userType=='Member'] | length([])" -o tsv)
    echo "Member Users: $MEMBER_COUNT" >> "$OUTPUT_DIR/02-azure-ad-users.txt"

    # Disabled accounts
    echo -e "\n=== Disabled User Accounts ===" >> "$OUTPUT_DIR/02-azure-ad-users.txt"
    az ad user list --query "[?accountEnabled==\`false\`].{Name:displayName, UPN:userPrincipalName, Type:userType}" --output table >> "$OUTPUT_DIR/02-azure-ad-users.txt"

    # Users by domain
    echo -e "\n=== Users by Domain ===" >> "$OUTPUT_DIR/02-azure-ad-users.txt"
    az ad user list --query "[].userPrincipalName" -o tsv | cut -d@ -f2 | sort | uniq -c >> "$OUTPUT_DIR/02-azure-ad-users.txt"
else
    echo "⚠️  No access to Azure AD user list" >> "$OUTPUT_DIR/02-azure-ad-users.txt"
    USER_COUNT="N/A"
    GUEST_COUNT="N/A"
    MEMBER_COUNT="N/A"
fi

# Export to JSON
az ad user list --output json > "$OUTPUT_DIR/02-azure-ad-users.json" 2>&1 || echo "{}" > "$OUTPUT_DIR/02-azure-ad-users.json"

################################################################################
# 3. Azure AD Groups
################################################################################
echo -e "${YELLOW}[3/8] Collecting Azure AD Groups...${NC}"

echo "=== Azure AD Groups ===" > "$OUTPUT_DIR/03-azure-ad-groups.txt"

if az ad group list --output table >> "$OUTPUT_DIR/03-azure-ad-groups.txt" 2>&1; then
    GROUP_COUNT=$(az ad group list --query 'length([])' -o tsv)
    echo -e "\n=== Group Statistics ===" >> "$OUTPUT_DIR/03-azure-ad-groups.txt"
    echo "Total Groups: $GROUP_COUNT" >> "$OUTPUT_DIR/03-azure-ad-groups.txt"

    # Security groups
    SECURITY_COUNT=$(az ad group list --query "[?securityEnabled==\`true\`] | length([])" -o tsv)
    echo "Security Enabled Groups: $SECURITY_COUNT" >> "$OUTPUT_DIR/03-azure-ad-groups.txt"

    # Mail-enabled groups
    MAIL_COUNT=$(az ad group list --query "[?mailEnabled==\`true\`] | length([])" -o tsv)
    echo "Mail Enabled Groups: $MAIL_COUNT" >> "$OUTPUT_DIR/03-azure-ad-groups.txt"
else
    echo "⚠️  No access to Azure AD group list" >> "$OUTPUT_DIR/03-azure-ad-groups.txt"
    GROUP_COUNT="N/A"
    SECURITY_COUNT="N/A"
    MAIL_COUNT="N/A"
fi

az ad group list --output json > "$OUTPUT_DIR/03-azure-ad-groups.json" 2>&1 || echo "{}" > "$OUTPUT_DIR/03-azure-ad-groups.json"

################################################################################
# 4. Service Principals & Applications
################################################################################
echo -e "${YELLOW}[4/8] Collecting Service Principals & Applications...${NC}"

echo "=== Service Principals ===" > "$OUTPUT_DIR/04-service-principals.txt"

if az ad sp list --all --query "[].{Name:displayName, AppId:appId, Type:servicePrincipalType, Enabled:accountEnabled}" --output table >> "$OUTPUT_DIR/04-service-principals.txt" 2>&1; then
    SP_COUNT=$(az ad sp list --all --query 'length([])' -o tsv)
    echo -e "\n=== Service Principal Statistics ===" >> "$OUTPUT_DIR/04-service-principals.txt"
    echo "Total Service Principals: $SP_COUNT" >> "$OUTPUT_DIR/04-service-principals.txt"
else
    echo "⚠️  No access to service principal list (this is normal for Tenant Reader)" >> "$OUTPUT_DIR/04-service-principals.txt"
    SP_COUNT="Limited"
fi

echo -e "\n=== App Registrations ===" >> "$OUTPUT_DIR/04-service-principals.txt"

if az ad app list --query "[].{Name:displayName, AppId:appId}" --output table >> "$OUTPUT_DIR/04-service-principals.txt" 2>&1; then
    APP_COUNT=$(az ad app list --query 'length([])' -o tsv)
    echo -e "\nTotal App Registrations: $APP_COUNT" >> "$OUTPUT_DIR/04-service-principals.txt"
else
    echo "⚠️  No access to application list" >> "$OUTPUT_DIR/04-service-principals.txt"
    APP_COUNT="Limited"
fi

################################################################################
# 5. Role Assignments (Your Access)
################################################################################
echo -e "${YELLOW}[5/8] Collecting Your Role Assignments...${NC}"

echo "=== Your Role Assignments ===" > "$OUTPUT_DIR/05-role-assignments.txt"
echo "User: $CURRENT_USER" >> "$OUTPUT_DIR/05-role-assignments.txt"
echo "" >> "$OUTPUT_DIR/05-role-assignments.txt"

az role assignment list --assignee "$CURRENT_USER" --all --output table >> "$OUTPUT_DIR/05-role-assignments.txt" 2>&1 || echo "Unable to retrieve role assignments"

echo -e "\n=== Role Summary ===" >> "$OUTPUT_DIR/05-role-assignments.txt"
az role assignment list --assignee "$CURRENT_USER" --all --query "[].{Role:roleDefinitionName, Scope:scope}" -o table >> "$OUTPUT_DIR/05-role-assignments.txt" 2>&1

################################################################################
# 6. Multi-Subscription Resource Discovery
################################################################################
echo -e "${YELLOW}[6/8] Scanning Resources Across Subscriptions...${NC}"

echo "=== Multi-Subscription Resource Summary ===" > "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "Scanning all accessible subscriptions for resources..." >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"

ACCESSIBLE_SUBS=0
TOTAL_RESOURCES=0

for sub_id in $(az account list --query "[].id" -o tsv); do
    sub_name=$(az account list --query "[?id=='$sub_id'].name" -o tsv)
    sub_state=$(az account list --query "[?id=='$sub_id'].state" -o tsv)

    echo -e "\n${CYAN}Checking: $sub_name ($sub_state)${NC}"
    echo "====================================" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
    echo "Subscription: $sub_name" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
    echo "ID: $sub_id" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
    echo "State: $sub_state" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
    echo "" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"

    # Set subscription context
    az account set --subscription "$sub_id" 2>/dev/null

    # Try to list resource groups
    if rg_count=$(az group list --query 'length([])' -o tsv 2>/dev/null); then
        echo "  ✓ Resource Groups: $rg_count" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
        ACCESSIBLE_SUBS=$((ACCESSIBLE_SUBS + 1))

        # Try to get resources
        if res_count=$(az resource list --query 'length([])' -o tsv 2>/dev/null); then
            echo "  ✓ Total Resources: $res_count" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
            TOTAL_RESOURCES=$((TOTAL_RESOURCES + res_count))

            # Get top resource types
            echo "  Top Resource Types:" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
            az resource list --query "[].type" -o tsv 2>/dev/null | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /' >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"

            # Try to get locations
            echo "  Locations in use:" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
            az resource list --query "[].location" -o tsv 2>/dev/null | sort | uniq | sed 's/^/    - /' >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
        else
            echo "  ⚠️  No access to resources" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
        fi
    else
        echo "  ✗ No access to this subscription" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
    fi
done

echo "" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "====================================" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "Scan Summary:" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "Total Subscriptions: $(az account list --query 'length([])' -o tsv)" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "Accessible Subscriptions: $ACCESSIBLE_SUBS" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"
echo "Total Resources Found: $TOTAL_RESOURCES" >> "$OUTPUT_DIR/06-multi-subscription-scan.txt"

################################################################################
# 7. Management Groups (if accessible)
################################################################################
echo -e "${YELLOW}[7/8] Checking Management Groups...${NC}"

echo "=== Management Groups ===" > "$OUTPUT_DIR/07-management-groups.txt"

if az account management-group list --output table >> "$OUTPUT_DIR/07-management-groups.txt" 2>&1; then
    MG_COUNT=$(az account management-group list --query 'length([])' -o tsv 2>/dev/null || echo "0")
    echo -e "\nTotal Management Groups: $MG_COUNT" >> "$OUTPUT_DIR/07-management-groups.txt"
else
    echo "⚠️  No access to management groups (requires additional permissions)" >> "$OUTPUT_DIR/07-management-groups.txt"
    MG_COUNT="N/A"
fi

################################################################################
# 8. Access Limitations Report
################################################################################
echo -e "${YELLOW}[8/8] Generating Access Limitations Report...${NC}"

cat > "$OUTPUT_DIR/08-access-limitations.txt" << EOF
=== Tenant Reader Access Limitations ===

Your current role: Tenant Reader

✅ What You CAN Access:
- Azure AD users, groups, and applications
- Subscription list in tenant
- Your own role assignments
- Service principal information (limited)
- Management groups (limited)

⚠️  What Requires Additional Permissions:

1. SUBSCRIPTION RESOURCES (needs: Reader role on subscription)
   - Virtual Machines
   - AKS Clusters
   - Storage Accounts
   - Databases
   - Network Resources (VNets, NSGs)
   - Detailed resource configurations

2. COST DATA (needs: Cost Management Reader role)
   - Current month spending
   - Cost by resource group
   - Budget information
   - Cost forecasts

3. SECURITY DATA (needs: Security Reader role)
   - Azure Defender status
   - Security recommendations
   - Security alerts
   - Compliance assessments

4. KEY VAULT SECRETS (needs: Key Vault Reader role)
   - Secret values
   - Certificate details
   - Key information

=== Resource Access Summary ===
Subscriptions Found: $(az account list --query 'length([])' -o tsv)
Subscriptions Accessible: $ACCESSIBLE_SUBS

$(if [ "$ACCESSIBLE_SUBS" -eq 0 ]; then
    echo "❌ No subscription-level access detected"
    echo ""
    echo "Recommendation: Request 'Reader' role on specific subscriptions"
    echo "to access infrastructure resources."
elif [ "$ACCESSIBLE_SUBS" -lt "$(az account list --query 'length([])' -o tsv)" ]; then
    echo "⚠️  Partial subscription access"
    echo ""
    echo "You have access to $ACCESSIBLE_SUBS out of $(az account list --query 'length([])' -o tsv) subscriptions."
    echo "Request 'Reader' role on additional subscriptions if needed."
else
    echo "✅ Full subscription access"
    echo ""
    echo "You have Reader access to all subscriptions in the tenant."
fi)

=== Requesting Additional Access ===

To access infrastructure resources, request these roles:

1. Reader (per subscription)
   - Scope: /subscriptions/{subscription-id}
   - Purpose: View all resources and configurations
   - Risk: None (read-only)

2. Cost Management Reader (per subscription)
   - Scope: /subscriptions/{subscription-id}
   - Purpose: View cost data and budgets
   - Risk: None (read-only)

3. Security Reader (per subscription)
   - Scope: /subscriptions/{subscription-id}
   - Purpose: View security recommendations and alerts
   - Risk: None (read-only)

Template email to send to your Azure administrator is available
in the CLOUDSHELL-TENANT-READER-GUIDE.md file.

EOF

################################################################################
# Generate Summary Report
################################################################################
echo -e "${YELLOW}Generating Summary Report...${NC}"

cat > "$OUTPUT_DIR/00-SUMMARY.txt" << EOF
╔══════════════════════════════════════════════════════════════╗
║          AZURE TENANT INVENTORY SUMMARY                      ║
║          Access Level: Tenant Reader                         ║
╚══════════════════════════════════════════════════════════════╝

Generated: $(date)
Tenant ID: $TENANT_ID
Current User: $CURRENT_USER

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AZURE AD STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Users:                  $USER_COUNT
  ├─ Members:           $MEMBER_COUNT
  └─ Guests:            $GUEST_COUNT

Groups:                 $GROUP_COUNT
  ├─ Security Enabled:  $SECURITY_COUNT
  └─ Mail Enabled:      $MAIL_COUNT

Service Principals:     $SP_COUNT
App Registrations:      $APP_COUNT
Management Groups:      $MG_COUNT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUBSCRIPTION ACCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Subscriptions:    $(az account list --query 'length([])' -o tsv)
Enabled Subscriptions:  $(az account list --query "[?state=='Enabled'] | length([])" -o tsv)
Accessible (with data): $ACCESSIBLE_SUBS
Total Resources Found:  $TOTAL_RESOURCES

$(if [ "$ACCESSIBLE_SUBS" -eq 0 ]; then
    echo "⚠️  WARNING: No subscription-level resource access"
    echo "   You have Tenant Reader but no subscription Reader roles."
    echo "   Request Reader role on subscriptions to see resources."
fi)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

01-tenant-info.txt              - Tenant and subscription details
02-azure-ad-users.txt           - User accounts and statistics
03-azure-ad-groups.txt          - Groups and memberships
04-service-principals.txt       - Service principals and apps
05-role-assignments.txt         - Your current role assignments
06-multi-subscription-scan.txt  - Resource scan across subscriptions
07-management-groups.txt        - Management group hierarchy
08-access-limitations.txt       - What you can/cannot access

All data also available in JSON format where applicable.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(if [ "$ACCESSIBLE_SUBS" -eq 0 ]; then
    echo "1. Request 'Reader' role on subscriptions for resource visibility"
    echo "2. Request 'Cost Management Reader' for cost analysis"
    echo "3. Review 08-access-limitations.txt for detailed guidance"
else
    echo "1. Review Azure AD users for inactive accounts"
    echo "2. Audit guest user access"
    echo "3. Check for disabled service principals"
    echo "4. Review multi-subscription resource distribution"
fi)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For detailed usage guide, see: CLOUDSHELL-TENANT-READER-GUIDE.md

EOF

################################################################################
# Create Archive
################################################################################
echo -e "${YELLOW}Creating archive...${NC}"
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR" 2>/dev/null

################################################################################
# Completion
################################################################################
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Inventory Complete!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📁 Results saved to:${NC} $OUTPUT_DIR"
echo -e "${CYAN}📦 Archive created:${NC} $OUTPUT_DIR.tar.gz"
echo ""
echo -e "${BLUE}View summary:${NC}"
echo -e "  cat $OUTPUT_DIR/00-SUMMARY.txt"
echo ""
echo -e "${BLUE}Download to local machine:${NC}"
echo -e "  1. In Cloud Shell: Click the Upload/Download icon"
echo -e "  2. Select 'Download' and enter: $OUTPUT_DIR.tar.gz"
echo ""

# Save to persistent storage if available
if [ -d ~/clouddrive ]; then
    echo -e "${YELLOW}Copying to persistent storage...${NC}"
    cp "$OUTPUT_DIR.tar.gz" ~/clouddrive/ 2>/dev/null && \
        echo -e "${GREEN}✓ Saved to ~/clouddrive/$OUTPUT_DIR.tar.gz${NC}" || \
        echo -e "${RED}✗ Could not save to clouddrive${NC}"
fi

exit 0

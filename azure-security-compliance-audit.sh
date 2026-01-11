#!/bin/bash
################################################################################
# Azure Security & Compliance Audit Script (Reader Access Only)
# Purpose: Security posture assessment and compliance checks
# Requirements: Azure CLI, Reader role (Security Reader recommended)
# Date: January 11, 2026
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OUTPUT_DIR="azure-security-audit-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}=== Azure Security & Compliance Audit ===${NC}"
echo -e "${BLUE}Output Directory: $OUTPUT_DIR${NC}\n"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

################################################################################
# 1. Security Center/Defender Status
################################################################################
echo -e "${YELLOW}[1/10] Checking Azure Security Center/Defender Status...${NC}"

echo "=== Azure Defender Status ===" > "$OUTPUT_DIR/01-security-center.txt"

# Check Security Center pricing tier
az security pricing list --output table >> "$OUTPUT_DIR/01-security-center.txt" 2>&1 || echo "Unable to access Security Center pricing info"

echo -e "\n=== Security Assessments ===" >> "$OUTPUT_DIR/01-security-center.txt"
az security assessment list --output table >> "$OUTPUT_DIR/01-security-center.txt" 2>&1 || echo "Security assessments not accessible"

echo -e "\n=== Security Alerts ===" >> "$OUTPUT_DIR/01-security-center.txt"
az security alert list --output table >> "$OUTPUT_DIR/01-security-center.txt" 2>&1 || echo "Security alerts not accessible"

################################################################################
# 2. Network Security Groups Analysis
################################################################################
echo -e "${YELLOW}[2/10] Analyzing Network Security Groups...${NC}"

echo "=== Network Security Groups ===" > "$OUTPUT_DIR/02-nsg-analysis.txt"

for nsg in $(az network nsg list --query "[].name" -o tsv); do
    rg=$(az network nsg list --query "[?name=='$nsg'].resourceGroup" -o tsv)
    echo -e "\n--- NSG: $nsg (RG: $rg) ---" >> "$OUTPUT_DIR/02-nsg-analysis.txt"

    # Get NSG rules
    az network nsg show --name "$nsg" --resource-group "$rg" --output table >> "$OUTPUT_DIR/02-nsg-analysis.txt" 2>&1

    # Check for overly permissive rules
    echo -e "\n  Security Rules:" >> "$OUTPUT_DIR/02-nsg-analysis.txt"
    az network nsg rule list --nsg-name "$nsg" --resource-group "$rg" --output table >> "$OUTPUT_DIR/02-nsg-analysis.txt" 2>&1

    # Flag dangerous rules (0.0.0.0/0 with allow)
    echo -e "\n  ⚠️  Checking for overly permissive rules..." >> "$OUTPUT_DIR/02-nsg-analysis.txt"
    az network nsg rule list --nsg-name "$nsg" --resource-group "$rg" \
        --query "[?access=='Allow' && (sourceAddressPrefix=='*' || sourceAddressPrefix=='0.0.0.0/0' || sourceAddressPrefix=='Internet')].{Name:name, Priority:priority, Source:sourceAddressPrefix, Dest:destinationPortRange, Protocol:protocol}" \
        --output table >> "$OUTPUT_DIR/02-nsg-analysis.txt" 2>&1
done

################################################################################
# 3. Public IP Addresses Exposure
################################################################################
echo -e "${YELLOW}[3/10] Checking Public IP Exposure...${NC}"

echo "=== Public IP Addresses ===" > "$OUTPUT_DIR/03-public-exposure.txt"
echo "Resources with public IPs (potential attack surface):" >> "$OUTPUT_DIR/03-public-exposure.txt"
echo "" >> "$OUTPUT_DIR/03-public-exposure.txt"

az network public-ip list --query "[].{Name:name, IP:ipAddress, AllocationMethod:publicIpAllocationMethod, AssociatedTo:ipConfiguration.id}" --output table >> "$OUTPUT_DIR/03-public-exposure.txt" 2>&1

# Count public IPs
PUBLIC_IP_COUNT=$(az network public-ip list --query "length([])" -o tsv)
echo -e "\n⚠️  Total Public IPs: $PUBLIC_IP_COUNT" >> "$OUTPUT_DIR/03-public-exposure.txt"

################################################################################
# 4. Storage Account Security
################################################################################
echo -e "${YELLOW}[4/10] Auditing Storage Account Security...${NC}"

echo "=== Storage Account Security ===" > "$OUTPUT_DIR/04-storage-security.txt"

for storage in $(az storage account list --query "[].name" -o tsv); do
    rg=$(az storage account list --query "[?name=='$storage'].resourceGroup" -o tsv)

    echo -e "\n--- Storage Account: $storage ---" >> "$OUTPUT_DIR/04-storage-security.txt"

    # Check HTTPS-only
    https_only=$(az storage account show --name "$storage" --resource-group "$rg" --query "enableHttpsTrafficOnly" -o tsv)
    echo "  HTTPS Only: $https_only" >> "$OUTPUT_DIR/04-storage-security.txt"
    if [ "$https_only" != "true" ]; then
        echo "  ⚠️  WARNING: HTTPS not enforced!" >> "$OUTPUT_DIR/04-storage-security.txt"
    fi

    # Check blob public access
    public_access=$(az storage account show --name "$storage" --resource-group "$rg" --query "allowBlobPublicAccess" -o tsv)
    echo "  Allow Blob Public Access: $public_access" >> "$OUTPUT_DIR/04-storage-security.txt"
    if [ "$public_access" == "true" ]; then
        echo "  ⚠️  WARNING: Public blob access is allowed!" >> "$OUTPUT_DIR/04-storage-security.txt"
    fi

    # Check minimum TLS version
    tls_version=$(az storage account show --name "$storage" --resource-group "$rg" --query "minimumTlsVersion" -o tsv)
    echo "  Minimum TLS Version: $tls_version" >> "$OUTPUT_DIR/04-storage-security.txt"
    if [ "$tls_version" != "TLS1_2" ] && [ "$tls_version" != "TLS1_3" ]; then
        echo "  ⚠️  WARNING: TLS version should be 1.2 or higher!" >> "$OUTPUT_DIR/04-storage-security.txt"
    fi

    # Check network rules
    echo "  Network Rules:" >> "$OUTPUT_DIR/04-storage-security.txt"
    az storage account show --name "$storage" --resource-group "$rg" --query "networkRuleSet.defaultAction" -o tsv >> "$OUTPUT_DIR/04-storage-security.txt" 2>&1
done

################################################################################
# 5. Key Vault Security Settings
################################################################################
echo -e "${YELLOW}[5/10] Checking Key Vault Security...${NC}"

echo "=== Key Vault Security Settings ===" > "$OUTPUT_DIR/05-keyvault-security.txt"

for kv in $(az keyvault list --query "[].name" -o tsv); do
    echo -e "\n--- Key Vault: $kv ---" >> "$OUTPUT_DIR/05-keyvault-security.txt"

    # Check soft delete and purge protection
    kv_info=$(az keyvault show --name "$kv" --query "{SoftDelete:properties.enableSoftDelete, PurgeProtection:properties.enablePurgeProtection, NetworkAcls:properties.networkAcls.defaultAction}" -o json)

    echo "$kv_info" | jq -r '. | to_entries | .[] | "  \(.key): \(.value)"' >> "$OUTPUT_DIR/05-keyvault-security.txt" 2>&1

    # Check for public network access
    network_acls=$(echo "$kv_info" | jq -r '.NetworkAcls // "Allow"')
    if [ "$network_acls" == "Allow" ]; then
        echo "  ⚠️  WARNING: Key Vault allows public network access!" >> "$OUTPUT_DIR/05-keyvault-security.txt"
    fi

    # List access policies (count only with reader access)
    echo "  Access Policies:" >> "$OUTPUT_DIR/05-keyvault-security.txt"
    az keyvault show --name "$kv" --query "properties.accessPolicies | length(@)" -o tsv >> "$OUTPUT_DIR/05-keyvault-security.txt" 2>&1
done

################################################################################
# 6. AKS Security Configuration
################################################################################
echo -e "${YELLOW}[6/10] Auditing AKS Security...${NC}"

echo "=== AKS Security Configuration ===" > "$OUTPUT_DIR/06-aks-security.txt"

for cluster in $(az aks list --query "[].name" -o tsv); do
    rg=$(az aks list --query "[?name=='$cluster'].resourceGroup" -o tsv)

    echo -e "\n--- AKS Cluster: $cluster ---" >> "$OUTPUT_DIR/06-aks-security.txt"

    # Get security-relevant settings
    aks_info=$(az aks show --name "$cluster" --resource-group "$rg" 2>&1)

    # Check RBAC
    rbac_enabled=$(echo "$aks_info" | jq -r '.enableRbac // false')
    echo "  RBAC Enabled: $rbac_enabled" >> "$OUTPUT_DIR/06-aks-security.txt"
    if [ "$rbac_enabled" != "true" ]; then
        echo "  ⚠️  WARNING: RBAC is not enabled!" >> "$OUTPUT_DIR/06-aks-security.txt"
    fi

    # Check Azure Policy
    azure_policy=$(echo "$aks_info" | jq -r '.addonProfiles.azurepolicy.enabled // false')
    echo "  Azure Policy Enabled: $azure_policy" >> "$OUTPUT_DIR/06-aks-security.txt"

    # Check network policy
    network_policy=$(echo "$aks_info" | jq -r '.networkProfile.networkPolicy // "none"')
    echo "  Network Policy: $network_policy" >> "$OUTPUT_DIR/06-aks-security.txt"
    if [ "$network_policy" == "none" ] || [ "$network_policy" == "null" ]; then
        echo "  ⚠️  WARNING: No network policy configured!" >> "$OUTPUT_DIR/06-aks-security.txt"
    fi

    # Check API server access
    api_access=$(echo "$aks_info" | jq -r '.apiServerAccessProfile.authorizedIpRanges // [] | length')
    echo "  API Server Authorized IP Ranges: $api_access" >> "$OUTPUT_DIR/06-aks-security.txt"
    if [ "$api_access" == "0" ]; then
        echo "  ⚠️  INFO: API server accessible from any IP" >> "$OUTPUT_DIR/06-aks-security.txt"
    fi

    # Check private cluster
    private_cluster=$(echo "$aks_info" | jq -r '.apiServerAccessProfile.enablePrivateCluster // false')
    echo "  Private Cluster: $private_cluster" >> "$OUTPUT_DIR/06-aks-security.txt"
done

################################################################################
# 7. VM Security Configuration
################################################################################
echo -e "${YELLOW}[7/10] Checking VM Security...${NC}"

echo "=== Virtual Machine Security ===" > "$OUTPUT_DIR/07-vm-security.txt"

for vm in $(az vm list --query "[].name" -o tsv); do
    rg=$(az vm list --query "[?name=='$vm'].resourceGroup" -o tsv)

    echo -e "\n--- VM: $vm ---" >> "$OUTPUT_DIR/07-vm-security.txt"

    # Check if VM has diagnostics enabled
    diag=$(az vm show --name "$vm" --resource-group "$rg" --query "diagnosticsProfile.bootDiagnostics.enabled" -o tsv 2>/dev/null || echo "unknown")
    echo "  Boot Diagnostics: $diag" >> "$OUTPUT_DIR/07-vm-security.txt"

    # Check VM extensions (security agents, monitoring)
    echo "  Extensions:" >> "$OUTPUT_DIR/07-vm-security.txt"
    az vm extension list --vm-name "$vm" --resource-group "$rg" --query "[].{Name:name, Type:typeHandlerVersion, State:provisioningState}" --output table >> "$OUTPUT_DIR/07-vm-security.txt" 2>&1

    # Check for managed identity
    identity=$(az vm show --name "$vm" --resource-group "$rg" --query "identity.type" -o tsv 2>/dev/null || echo "none")
    echo "  Managed Identity: $identity" >> "$OUTPUT_DIR/07-vm-security.txt"
done

################################################################################
# 8. Database Security
################################################################################
echo -e "${YELLOW}[8/10] Auditing Database Security...${NC}"

echo "=== Database Security ===" > "$OUTPUT_DIR/08-database-security.txt"

# SQL Servers
for server in $(az sql server list --query "[].name" -o tsv 2>/dev/null); do
    rg=$(az sql server list --query "[?name=='$server'].resourceGroup" -o tsv)

    echo -e "\n--- SQL Server: $server ---" >> "$OUTPUT_DIR/08-database-security.txt"

    # Check firewall rules
    echo "  Firewall Rules:" >> "$OUTPUT_DIR/08-database-security.txt"
    az sql server firewall-rule list --server "$server" --resource-group "$rg" --output table >> "$OUTPUT_DIR/08-database-security.txt" 2>&1

    # Check for 0.0.0.0 - 255.255.255.255 rule (allow all)
    allow_all=$(az sql server firewall-rule list --server "$server" --resource-group "$rg" --query "[?startIpAddress=='0.0.0.0' && endIpAddress=='255.255.255.255'].name" -o tsv)
    if [ -n "$allow_all" ]; then
        echo "  ⚠️  WARNING: 'Allow All' firewall rule detected!" >> "$OUTPUT_DIR/08-database-security.txt"
    fi

    # Check TLS version
    tls=$(az sql server show --name "$server" --resource-group "$rg" --query "minimalTlsVersion" -o tsv 2>/dev/null || echo "unknown")
    echo "  Minimum TLS Version: $tls" >> "$OUTPUT_DIR/08-database-security.txt"

    # Check Azure AD admin
    ad_admin=$(az sql server ad-admin list --server "$server" --resource-group "$rg" --query "[].login" -o tsv 2>/dev/null || echo "not configured")
    echo "  Azure AD Admin: $ad_admin" >> "$OUTPUT_DIR/08-database-security.txt"
done

################################################################################
# 9. Identity and Access Management
################################################################################
echo -e "${YELLOW}[9/10] Checking IAM Configuration...${NC}"

echo "=== Identity and Access Management ===" > "$OUTPUT_DIR/09-iam-analysis.txt"

# List all role assignments at subscription level
echo "=== Subscription-level Role Assignments ===" >> "$OUTPUT_DIR/09-iam-analysis.txt"
az role assignment list --scope "/subscriptions/$SUBSCRIPTION_ID" --output table >> "$OUTPUT_DIR/09-iam-analysis.txt" 2>&1

# Check for Owner/Contributor assignments
echo -e "\n=== High-Privilege Role Assignments (Owner/Contributor) ===" >> "$OUTPUT_DIR/09-iam-analysis.txt"
az role assignment list --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor'].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
    --output table >> "$OUTPUT_DIR/09-iam-analysis.txt" 2>&1

# Check for custom roles
echo -e "\n=== Custom Roles ===" >> "$OUTPUT_DIR/09-iam-analysis.txt"
az role definition list --custom-role-only true --output table >> "$OUTPUT_DIR/09-iam-analysis.txt" 2>&1

################################################################################
# 10. Compliance and Policy Assignments
################################################################################
echo -e "${YELLOW}[10/10] Checking Azure Policy Compliance...${NC}"

echo "=== Azure Policy Assignments ===" > "$OUTPUT_DIR/10-compliance.txt"
az policy assignment list --output table >> "$OUTPUT_DIR/10-compliance.txt" 2>&1

echo -e "\n=== Policy Compliance State ===" >> "$OUTPUT_DIR/10-compliance.txt"
az policy state summarize --output table >> "$OUTPUT_DIR/10-compliance.txt" 2>&1 || echo "Policy state not accessible"

echo -e "\n=== Non-Compliant Resources ===" >> "$OUTPUT_DIR/10-compliance.txt"
az policy state list --filter "ComplianceState eq 'NonCompliant'" --output table >> "$OUTPUT_DIR/10-compliance.txt" 2>&1 || echo "Policy state details not accessible"

################################################################################
# Generate Security Summary Report
################################################################################
echo -e "${YELLOW}Generating Security Summary...${NC}"

cat > "$OUTPUT_DIR/00-SECURITY-SUMMARY.txt" << EOF
===========================================
AZURE SECURITY & COMPLIANCE AUDIT SUMMARY
===========================================
Generated: $(date)
Subscription: $SUBSCRIPTION_ID

This report contains security findings based on reader-level access.
For complete security assessment, Security Reader or higher role is recommended.

--- Files Generated ---
01-security-center.txt       - Azure Defender/Security Center status
02-nsg-analysis.txt          - Network Security Group rules audit
03-public-exposure.txt       - Public IP addresses inventory
04-storage-security.txt      - Storage account security settings
05-keyvault-security.txt     - Key Vault security configuration
06-aks-security.txt          - AKS cluster security settings
07-vm-security.txt           - Virtual machine security
08-database-security.txt     - Database security configuration
09-iam-analysis.txt          - Role assignments and permissions
10-compliance.txt            - Azure Policy compliance status

--- Key Metrics ---
Public IPs: $PUBLIC_IP_COUNT
Network Security Groups: $(az network nsg list --query "length([])" -o tsv)
Storage Accounts: $(az storage account list --query "length([])" -o tsv)
Key Vaults: $(az keyvault list --query "length([])" -o tsv)
AKS Clusters: $(az aks list --query "length([])" -o tsv)

--- Common Security Findings to Review ---
1. NSG rules allowing traffic from 0.0.0.0/0 (Internet)
2. Storage accounts without HTTPS-only enforcement
3. Storage accounts allowing public blob access
4. Key Vaults accessible from public networks
5. SQL servers with 'Allow All' firewall rules
6. Resources without encryption at rest
7. Missing network policies in AKS clusters
8. VMs without security extensions

--- Recommended Actions ---
1. Review and restrict overly permissive NSG rules
2. Enable Azure Defender for all resource types
3. Implement Private Link for PaaS services
4. Enable encryption at rest for all data stores
5. Enforce HTTPS-only and TLS 1.2+ minimum
6. Implement network policies in AKS
7. Enable Azure Policy for governance
8. Regular security assessment reviews

===========================================
EOF

################################################################################
# Completion
################################################################################
echo -e "${GREEN}✓ Security Audit Complete!${NC}"
echo -e "${BLUE}Results saved to: $OUTPUT_DIR${NC}"
echo -e "${BLUE}View summary: cat $OUTPUT_DIR/00-SECURITY-SUMMARY.txt${NC}"

# Create archive
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
echo -e "${GREEN}✓ Archive created: $OUTPUT_DIR.tar.gz${NC}"

exit 0

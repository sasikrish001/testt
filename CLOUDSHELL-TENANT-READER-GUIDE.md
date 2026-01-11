# Azure Cloud Shell - Tenant Reader Access Guide

**Environment:** Azure Cloud Shell
**Access Level:** Tenant Reader (Read-Only across all subscriptions in tenant)
**Last Updated:** January 11, 2026

---

## 🎯 What is Tenant Reader Access?

**Tenant Reader** is an Azure AD role that provides:
- ✅ Read access to Azure AD (Entra ID) resources
- ✅ View users, groups, applications, and service principals
- ✅ Limited visibility into subscription resources
- ✅ Multi-subscription visibility within the tenant
- ❌ Cannot view detailed resource configurations (needs Subscription Reader)
- ❌ Cannot access cost data (needs Cost Management Reader)
- ❌ Cannot modify any resources

**Key Difference from Subscription Reader:**
- **Tenant Reader:** Azure AD/Entra ID level (identity & governance)
- **Subscription Reader:** Subscription level (resources, VMs, storage, etc.)

---

## ⚡ Quick Start in Cloud Shell

### 1. Launch Cloud Shell
- Go to: https://portal.azure.com
- Click the Cloud Shell icon (>_) in the top menu
- Choose **Bash** environment

### 2. Verify Your Access
```bash
# Check current account
az account show

# List all subscriptions you can see
az account list --output table

# Check your tenant
az account show --query tenantId -o tsv

# List your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

### 3. Set Target Subscription
```bash
# List subscriptions
az account list --output table

# Set the subscription you want to work with
az account set --subscription "SUBSCRIPTION_NAME_OR_ID"

# Verify
az account show --query "{Name:name, ID:id, State:state}" -o table
```

---

## 🔍 What You CAN Do with Tenant Reader

### Azure AD / Entra ID Queries

```bash
# List all users in tenant
az ad user list --output table

# Count users
az ad user list --query "length([])" -o tsv

# List all groups
az ad group list --output table

# List service principals / applications
az ad sp list --all --output table

# Get specific user details
az ad user show --id "user@domain.com"

# List group members
az ad group member list --group "GROUP_NAME" --output table

# List app registrations
az ad app list --output table

# Show directory role assignments
az rest --method GET --url "https://graph.microsoft.com/v1.0/directoryRoles" \
  --query "value[].{Name:displayName, Description:description}" -o table
```

### Multi-Subscription Queries

```bash
# Get resources across ALL subscriptions
for sub in $(az account list --query "[].id" -o tsv); do
  echo "=== Subscription: $(az account list --query "[?id=='$sub'].name" -o tsv) ==="
  az account set --subscription "$sub"
  az resource list --query "length([])" -o tsv 2>/dev/null || echo "No access"
done

# Count resource groups across all subscriptions
for sub in $(az account list --query "[].id" -o tsv); do
  az account set --subscription "$sub"
  count=$(az group list --query "length([])" -o tsv 2>/dev/null || echo "0")
  echo "$(az account show --query name -o tsv): $count resource groups"
done
```

### Tenant-Level Information

```bash
# Tenant details
az account show --query "{TenantID:tenantId, Domain:user.name}" -o table

# All subscriptions in tenant (that you can see)
az account list --query "[].{Name:name, ID:id, State:state}" -o table

# Management groups (if accessible)
az account management-group list --output table

# Policy definitions at tenant level
az policy definition list --management-group ROOT_MG_ID --output table
```

---

## ⚠️ What You CANNOT Do (Common Limitations)

### Limited Resource Access
```bash
# These commands may fail or return limited data with Tenant Reader:

# Resource details (needs Subscription Reader)
az resource show --ids /subscriptions/.../resourceGroups/.../providers/...
# Error: AuthorizationFailed

# Cost data (needs Cost Management Reader)
az costmanagement query --type "Usage" --timeframe "MonthToDate" --scope "..."
# Error: Insufficient permissions

# Key Vault secrets (needs Key Vault Reader)
az keyvault secret show --vault-name "..." --name "..."
# Error: Forbidden

# Detailed VM information (needs Subscription Reader)
az vm list -d
# May return empty or limited data
```

---

## 🛠️ Adapted Scripts for Tenant Reader

### Script 1: Tenant-Level Inventory

Create a file: `tenant-inventory.sh`

```bash
#!/bin/bash
################################################################################
# Tenant-Level Inventory (Tenant Reader Access)
# Works with: Azure Cloud Shell + Tenant Reader role
################################################################################

OUTPUT_DIR="tenant-inventory-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "=== Azure Tenant Inventory ==="
echo "Output: $OUTPUT_DIR"

# Tenant Information
echo "=== Tenant Information ===" > "$OUTPUT_DIR/01-tenant-info.txt"
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID" >> "$OUTPUT_DIR/01-tenant-info.txt"
echo "Current User: $(az account show --query user.name -o tsv)" >> "$OUTPUT_DIR/01-tenant-info.txt"
echo "" >> "$OUTPUT_DIR/01-tenant-info.txt"

# Subscriptions
echo "=== Subscriptions ===" >> "$OUTPUT_DIR/01-tenant-info.txt"
az account list --output table >> "$OUTPUT_DIR/01-tenant-info.txt"

# Azure AD Users
echo "=== Azure AD Users ===" > "$OUTPUT_DIR/02-aad-users.txt"
az ad user list --output table >> "$OUTPUT_DIR/02-aad-users.txt" 2>&1 || echo "No access to user list"

USER_COUNT=$(az ad user list --query "length([])" -o tsv 2>/dev/null || echo "N/A")
echo "Total Users: $USER_COUNT" >> "$OUTPUT_DIR/02-aad-users.txt"

# Azure AD Groups
echo "=== Azure AD Groups ===" > "$OUTPUT_DIR/03-aad-groups.txt"
az ad group list --output table >> "$OUTPUT_DIR/03-aad-groups.txt" 2>&1 || echo "No access to group list"

GROUP_COUNT=$(az ad group list --query "length([])" -o tsv 2>/dev/null || echo "N/A")
echo "Total Groups: $GROUP_COUNT" >> "$OUTPUT_DIR/03-aad-groups.txt"

# Service Principals
echo "=== Service Principals ===" > "$OUTPUT_DIR/04-service-principals.txt"
az ad sp list --all --query "[].{Name:displayName, AppId:appId, Type:servicePrincipalType}" --output table >> "$OUTPUT_DIR/04-service-principals.txt" 2>&1 || echo "No access to service principals"

# Applications
echo "=== App Registrations ===" > "$OUTPUT_DIR/05-app-registrations.txt"
az ad app list --query "[].{Name:displayName, AppId:appId}" --output table >> "$OUTPUT_DIR/05-app-registrations.txt" 2>&1 || echo "No access to applications"

# Try to get resources from each subscription
echo "=== Multi-Subscription Resource Summary ===" > "$OUTPUT_DIR/06-multi-sub-resources.txt"
for sub_id in $(az account list --query "[].id" -o tsv); do
    sub_name=$(az account list --query "[?id=='$sub_id'].name" -o tsv)
    echo "" >> "$OUTPUT_DIR/06-multi-sub-resources.txt"
    echo "--- Subscription: $sub_name ---" >> "$OUTPUT_DIR/06-multi-sub-resources.txt"

    az account set --subscription "$sub_id" 2>/dev/null

    # Try to get resource groups
    rg_count=$(az group list --query "length([])" -o tsv 2>/dev/null || echo "No access")
    echo "Resource Groups: $rg_count" >> "$OUTPUT_DIR/06-multi-sub-resources.txt"

    # Try to get resource count
    res_count=$(az resource list --query "length([])" -o tsv 2>/dev/null || echo "No access")
    echo "Total Resources: $res_count" >> "$OUTPUT_DIR/06-multi-sub-resources.txt"
done

# Summary
cat > "$OUTPUT_DIR/00-SUMMARY.txt" << EOF
===========================================
TENANT-LEVEL INVENTORY SUMMARY
===========================================
Generated: $(date)
Tenant ID: $TENANT_ID

Access Level: Tenant Reader
Note: Limited resource visibility - consider requesting Subscription Reader

--- Azure AD Statistics ---
Users: $USER_COUNT
Groups: $GROUP_COUNT
Subscriptions: $(az account list --query "length([])" -o tsv)

--- Files Generated ---
01-tenant-info.txt           - Tenant and subscription info
02-aad-users.txt             - Azure AD users
03-aad-groups.txt            - Azure AD groups
04-service-principals.txt    - Service principals
05-app-registrations.txt     - App registrations
06-multi-sub-resources.txt   - Multi-subscription summary

===========================================
EOF

echo "✓ Inventory complete: $OUTPUT_DIR"
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
echo "✓ Archive: $OUTPUT_DIR.tar.gz"
```

### Script 2: Azure AD User Report

```bash
#!/bin/bash
################################################################################
# Azure AD User Report (Tenant Reader)
################################################################################

OUTPUT_FILE="aad-user-report-$(date +%Y%m%d).txt"

echo "=== Azure AD User Report ===" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# All users
echo "=== All Users ===" >> "$OUTPUT_FILE"
az ad user list --output table >> "$OUTPUT_FILE"

# Users by domain
echo "" >> "$OUTPUT_FILE"
echo "=== Users by Domain ===" >> "$OUTPUT_FILE"
az ad user list --query "[].userPrincipalName" -o tsv | cut -d@ -f2 | sort | uniq -c

# Disabled users
echo "" >> "$OUTPUT_FILE"
echo "=== Disabled Users ===" >> "$OUTPUT_FILE"
az ad user list --query "[?accountEnabled==\`false\`].{Name:displayName, UPN:userPrincipalName}" --output table >> "$OUTPUT_FILE"

echo "✓ Report saved: $OUTPUT_FILE"
```

### Script 3: Role Assignment Report

```bash
#!/bin/bash
################################################################################
# Cross-Subscription Role Assignment Report
################################################################################

OUTPUT_FILE="role-assignments-$(date +%Y%m%d).txt"

echo "=== Role Assignments Across Subscriptions ===" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"

for sub_id in $(az account list --query "[].id" -o tsv); do
    sub_name=$(az account list --query "[?id=='$sub_id'].name" -o tsv)

    echo "" >> "$OUTPUT_FILE"
    echo "=====================================" >> "$OUTPUT_FILE"
    echo "Subscription: $sub_name" >> "$OUTPUT_FILE"
    echo "=====================================" >> "$OUTPUT_FILE"

    az account set --subscription "$sub_id"

    # Get role assignments
    az role assignment list --all --output table >> "$OUTPUT_FILE" 2>&1 || echo "No access to role assignments"
done

echo "✓ Report saved: $OUTPUT_FILE"
```

---

## 📊 Useful Tenant Reader Queries

### Identity & Access

```bash
# Find users with specific role
az ad user list --query "[?jobTitle=='Administrator'].{Name:displayName, Email:userPrincipalName}" -o table

# List guest users
az ad user list --query "[?userType=='Guest'].{Name:displayName, Email:userPrincipalName}" -o table

# Service principals owned by your org
az ad sp list --all --query "[?publisherName=='Your Company'].{Name:displayName, AppId:appId}" -o table

# Find disabled service principals
az ad sp list --all --query "[?accountEnabled==\`false\`].displayName" -o tsv
```

### Multi-Subscription Analysis

```bash
# List all subscriptions with state
az account list --query "[].{Name:name, State:state, ID:id}" -o table

# Count subscriptions by state
az account list --query "[].state" -o tsv | sort | uniq -c

# Find subscriptions you can access
for sub in $(az account list --query "[].id" -o tsv); do
  az account set --subscription "$sub"
  if az group list >/dev/null 2>&1; then
    echo "✓ Access to: $(az account show --query name -o tsv)"
  else
    echo "✗ No access to: $(az account show --query name -o tsv)"
  fi
done
```

### Governance

```bash
# Management groups
az account management-group list --output table

# Show subscription to management group mapping
az account management-group subscription show --name "MG_NAME" --subscription "SUB_ID"
```

---

## 🎯 Requesting Additional Access

Since you have **Tenant Reader** but may need resource-level access, here's a template:

```
To: Azure Administrator / IT Support
Subject: Request for Additional Azure Subscription Access

Current Access: Tenant Reader
Requested Access: Reader role on subscription(s) [SUBSCRIPTION_NAME]

Purpose:
- Infrastructure inventory and documentation
- Cost analysis and optimization reporting
- Security compliance auditing

Business Justification:
[Your reason here]

Note: This is a read-only role and will not allow modifications.

Subscription(s) needed:
- [Subscription 1 Name/ID]
- [Subscription 2 Name/ID]

Thank you,
[Your Name]
```

---

## 🚀 Cloud Shell Tips

### Persist Your Scripts in Cloud Shell

```bash
# Cloud Shell has persistent storage mounted at ~/clouddrive
cd ~/clouddrive

# Create a scripts directory
mkdir -p scripts
cd scripts

# Upload scripts here - they persist across sessions
# Download scripts from your repo
curl -o tenant-inventory.sh https://raw.githubusercontent.com/YOUR_REPO/tenant-inventory.sh
chmod +x tenant-inventory.sh

# Run from anywhere
~/clouddrive/scripts/tenant-inventory.sh
```

### Create Aliases

```bash
# Edit .bashrc
nano ~/.bashrc

# Add aliases
alias azls='az account list --output table'
alias azset='az account set --subscription'
alias azshow='az account show'
alias adusers='az ad user list --output table'
alias adgroups='az ad group list --output table'

# Reload
source ~/.bashrc
```

### Schedule Reports (within Cloud Shell session)

```bash
# Run a report every hour (while Cloud Shell is active)
while true; do
  ./tenant-inventory.sh
  sleep 3600
done &
```

---

## 🔍 Troubleshooting Common Issues

### Issue: "Authorization Failed" on Resource Queries

**Cause:** Tenant Reader doesn't include subscription resource access

**Solution:**
```bash
# Check if you have subscription-level roles
az role assignment list --assignee $(az account show --query user.name -o tsv) --all

# Request Reader role on specific subscriptions
```

### Issue: "Insufficient Privileges" for Cost Data

**Cause:** Tenant Reader doesn't include cost access

**Solution:**
- Request "Cost Management Reader" role on subscription
- Alternative: Use Azure Portal Cost Analysis (may have different permissions)

### Issue: Empty Results for Resource Queries

**Check your subscription context:**
```bash
az account show
az account list --output table
az account set --subscription "CORRECT_SUB_ID"
```

### Issue: Cloud Shell Timeout

**Cloud Shell times out after 20 minutes of inactivity**

**Solution:**
```bash
# Keep session alive
while true; do echo "keep-alive: $(date)"; sleep 300; done &

# Or reconnect and continue (files in ~/clouddrive persist)
```

---

## 📋 Quick Reference for Tenant Reader

### Essential Commands

```bash
# Tenant info
az account show --query "{Tenant:tenantId, User:user.name}"

# All subscriptions
az account list -o table

# Azure AD users
az ad user list -o table

# Azure AD groups
az ad group list -o table

# Service principals
az ad sp list --all -o table

# Your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) -o table

# Switch subscription
az account set --subscription "NAME_OR_ID"
```

---

## 💡 What to Focus On

With **Tenant Reader** access, you're best positioned for:

1. **Identity & Access Governance**
   - User lifecycle management reporting
   - Group membership auditing
   - Service principal inventory
   - Role assignment tracking

2. **Multi-Subscription Visibility**
   - Cross-subscription compliance
   - Subscription inventory
   - Management group structure

3. **Azure AD Analysis**
   - Guest user reporting
   - Inactive user identification
   - Application registration inventory

**For infrastructure work** (VMs, AKS, storage, costs):
- Request **Reader** role on specific subscriptions
- Request **Cost Management Reader** for cost data

---

## 📚 Resources

- [Azure Tenant Reader Role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#tenant-reader)
- [Azure Cloud Shell Overview](https://learn.microsoft.com/azure/cloud-shell/overview)
- [Azure AD Graph API Permissions](https://learn.microsoft.com/graph/permissions-reference)

---

**Pro Tip:** Keep this guide in your Cloud Shell:
```bash
cd ~/clouddrive
curl -o TENANT-READER-GUIDE.md [URL_TO_THIS_FILE]
```

**Last Updated:** January 11, 2026

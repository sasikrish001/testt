# Azure Reader Access - Quick Reference Card

**One-page cheat sheet for common Azure reader operations**

---

## 🚀 Quick Start Commands

### Login & Setup
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
az account show  # Verify
```

---

## 📊 Resource Discovery (1-Liners)

```bash
# All resources
az resource list --output table

# By type
az resource list --resource-type "Microsoft.Compute/virtualMachines" --output table

# By resource group
az resource list --resource-group "YOUR_RG" --output table

# Resource count by type
az resource list --query "[].type" -o tsv | sort | uniq -c | sort -rn

# All resource groups
az group list --output table

# Resources without tags
az resource list --query "[?tags==null].{Name:name, Type:type}" --output table
```

---

## 💰 Cost Analysis (1-Liners)

```bash
# Current month total
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table

# By resource group
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table

# By service
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --dataset-grouping name=MeterCategory type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table

# Top 10 expensive resources
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceId type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "properties.rows[:10]" --output table
```

---

## 🔍 Specific Resource Queries

### AKS Clusters
```bash
az aks list --output table
az aks show --name CLUSTER_NAME --resource-group RG_NAME
az aks nodepool list --cluster-name CLUSTER_NAME --resource-group RG_NAME --output table
```

### Virtual Machines
```bash
az vm list --output table
az vm list -d --output table  # Include power state
az vm show --name VM_NAME --resource-group RG_NAME
```

### Storage Accounts
```bash
az storage account list --output table
az storage account show --name STORAGE_NAME --resource-group RG_NAME
```

### Container Registries
```bash
az acr list --output table
az acr repository list --name ACR_NAME --output table
```

### Networking
```bash
az network vnet list --output table
az network nsg list --output table
az network public-ip list --output table
az network lb list --output table
```

### Databases
```bash
az sql server list --output table
az sql db list --server SERVER_NAME --resource-group RG_NAME --output table
az postgres server list --output table
az mysql server list --output table
az cosmosdb list --output table
```

### Key Vaults
```bash
az keyvault list --output table
az keyvault secret list --vault-name VAULT_NAME --query "[].name" --output table
```

---

## 🔐 Security Checks (1-Liners)

```bash
# Security recommendations
az advisor recommendation list --category Security --output table

# NSG rules
az network nsg list --query "[].name" -o tsv | xargs -I {} \
  az network nsg rule list --nsg-name {} --query "[?access=='Allow' && sourceAddressPrefix=='*']" -o table

# Public IPs
az network public-ip list --query "[].{Name:name, IP:ipAddress}" --output table

# Storage HTTPS enforcement
az storage account list --query "[].{Name:name, HTTPS:enableHttpsTrafficOnly}" --output table

# SQL firewall rules
az sql server list --query "[].name" -o tsv | xargs -I {} \
  az sql server firewall-rule list --server {} --query "[].{Name:name, Start:startIpAddress, End:endIpAddress}" -o table
```

---

## 📈 Monitoring & Logs

```bash
# Log Analytics workspaces
az monitor log-analytics workspace list --output table

# Application Insights
az monitor app-insights component list --output table

# Diagnostic settings
az monitor diagnostic-settings list --resource RESOURCE_ID
```

---

## 🏷️ Tags & Organization

```bash
# Resources by tag
az resource list --tag Environment=Production --output table

# All tags
az tag list --output table

# Resources without specific tag
az resource list --query "[?tags.Environment==null].{Name:name, Type:type}" --output table
```

---

## 🎯 Azure Advisor

```bash
# All recommendations
az advisor recommendation list --output table

# Cost recommendations
az advisor recommendation list --category Cost --output table

# High availability recommendations
az advisor recommendation list --category HighAvailability --output table

# Performance recommendations
az advisor recommendation list --category Performance --output table

# Security recommendations
az advisor recommendation list --category Security --output table
```

---

## 📦 Export Data

```bash
# Export to JSON
az resource list --output json > resources.json

# Export to CSV (with jq)
az resource list --output json | jq -r '.[] | [.name, .type, .location, .resourceGroup] | @csv' > resources.csv

# Export to table file
az resource list --output table > resources.txt
```

---

## 🛠️ Useful Filters & Queries

```bash
# Resources in specific location
az resource list --location "eastus" --output table

# Resources created after date
az resource list --query "[?createdTime>='2026-01-01']" --output table

# Resources by name pattern
az resource list --query "[?contains(name, 'prod')]" --output table

# Resources with specific property
az resource list --query "[?sku.tier=='Standard']" --output table
```

---

## 🔄 Bulk Operations (Read-Only)

```bash
# Get all VM sizes
az vm list-sizes --location "eastus" --output table

# List all available SKUs
az resource list --query "[].sku" --output table

# Get all resource types in subscription
az resource list --query "[].type" -o tsv | sort -u

# Count resources by location
az resource list --query "[].location" -o tsv | sort | uniq -c | sort -rn
```

---

## 📊 Quick Reports

### Daily Cost Check
```bash
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### Resource Summary
```bash
echo "Resource Groups: $(az group list --query 'length([])'  -o tsv)"
echo "Total Resources: $(az resource list --query 'length([])' -o tsv)"
echo "AKS Clusters: $(az aks list --query 'length([])' -o tsv)"
echo "VMs: $(az vm list --query 'length([])' -o tsv)"
echo "Storage Accounts: $(az storage account list --query 'length([])' -o tsv)"
```

### Security Quick Check
```bash
echo "=== Security Quick Check ==="
echo "Public IPs: $(az network public-ip list --query 'length([])' -o tsv)"
echo "NSGs: $(az network nsg list --query 'length([])' -o tsv)"
az advisor recommendation list --category Security --query "length([])" -o tsv
```

---

## 🔍 Troubleshooting Commands

```bash
# Check current context
az account show

# List subscriptions
az account list --output table

# Check role assignments
az role assignment list --assignee YOUR_EMAIL --output table

# Verify CLI version
az version

# Clear CLI cache
az cache purge

# Get CLI help
az --help
az COMMAND --help
```

---

## 💡 Pro Tips

### 1. Use JMESPath queries for advanced filtering
```bash
az resource list --query "[?location=='eastus' && tags.environment=='prod'].{Name:name, Type:type}"
```

### 2. Set default output format
```bash
az config set core.output=table
```

### 3. Use aliases for common commands
```bash
alias azr='az resource list --output table'
alias azc='az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum --timeframe "MonthToDate"'
alias azg='az group list --output table'
```

### 4. Combine with standard tools
```bash
# Count VMs by size
az vm list --query "[].hardwareProfile.vmSize" -o tsv | sort | uniq -c

# Find expensive resources
az resource list -o json | jq -r '.[] | select(.tags.cost_center=="engineering") | .name'

# Export with timestamp
az resource list -o table > "resources-$(date +%Y%m%d).txt"
```

---

## 📱 Azure Portal Quick Links

- **Cost Analysis:** https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis
- **Azure Advisor:** https://portal.azure.com/#view/Microsoft_Azure_Expert/AdvisorMenuBlade/~/overview
- **All Resources:** https://portal.azure.com/#view/HubsExtension/BrowseAll
- **Resource Groups:** https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups
- **Security Center:** https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/overview

---

## 🔗 Quick Scripts

### Daily Summary Script
```bash
#!/bin/bash
echo "=== Azure Daily Summary $(date) ==="
echo ""
echo "Subscription: $(az account show --query name -o tsv)"
echo "Total Resources: $(az resource list --query 'length([])' -o tsv)"
echo ""
echo "Month-to-Date Cost:"
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "properties.rows[0][0]" -o tsv | awk '{printf "$%.2f\n", $1}'
```

### Find Untagged Resources
```bash
#!/bin/bash
echo "=== Untagged Resources ==="
az resource list --query "[?tags==null || tags=={}].{Name:name, Type:type, RG:resourceGroup}" --output table
```

---

**Save this file for quick reference!**

**Tip:** Print or keep this page handy for day-to-day Azure operations with reader access.

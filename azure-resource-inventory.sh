#!/bin/bash
################################################################################
# Azure Resource Inventory Script (Reader Access Only)
# Purpose: Discover and document all Azure infrastructure resources
# Requirements: Azure CLI, Reader role or higher
# Date: January 11, 2026
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output directory
OUTPUT_DIR="azure-inventory-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}=== Azure Resource Inventory Tool ===${NC}"
echo -e "${BLUE}Output Directory: $OUTPUT_DIR${NC}\n"

################################################################################
# 1. Account and Subscription Information
################################################################################
echo -e "${YELLOW}[1/12] Collecting Account Information...${NC}"

echo "=== Azure Account Information ===" > "$OUTPUT_DIR/01-account-info.txt"
az account show >> "$OUTPUT_DIR/01-account-info.txt" 2>&1 || echo "Failed to get account info"

echo -e "\n=== All Subscriptions ===" >> "$OUTPUT_DIR/01-account-info.txt"
az account list --output table >> "$OUTPUT_DIR/01-account-info.txt" 2>&1 || echo "Failed to list subscriptions"

# Get current subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "\n=== Current Subscription ID: $SUBSCRIPTION_ID ===" >> "$OUTPUT_DIR/01-account-info.txt"

################################################################################
# 2. Resource Groups
################################################################################
echo -e "${YELLOW}[2/12] Collecting Resource Groups...${NC}"

echo "=== Resource Groups ===" > "$OUTPUT_DIR/02-resource-groups.txt"
az group list --output table >> "$OUTPUT_DIR/02-resource-groups.txt" 2>&1
az group list --output json > "$OUTPUT_DIR/02-resource-groups.json" 2>&1

################################################################################
# 3. All Resources Overview
################################################################################
echo -e "${YELLOW}[3/12] Collecting All Resources...${NC}"

echo "=== All Resources ===" > "$OUTPUT_DIR/03-all-resources.txt"
az resource list --output table >> "$OUTPUT_DIR/03-all-resources.txt" 2>&1
az resource list --output json > "$OUTPUT_DIR/03-all-resources.json" 2>&1

# Resource count by type
echo -e "\n=== Resource Count by Type ===" >> "$OUTPUT_DIR/03-all-resources.txt"
az resource list --query "[].type" -o tsv | sort | uniq -c | sort -rn >> "$OUTPUT_DIR/03-all-resources.txt" 2>&1

################################################################################
# 4. AKS Clusters
################################################################################
echo -e "${YELLOW}[4/12] Collecting AKS Clusters...${NC}"

echo "=== AKS Clusters ===" > "$OUTPUT_DIR/04-aks-clusters.txt"
az aks list --output table >> "$OUTPUT_DIR/04-aks-clusters.txt" 2>&1
az aks list --output json > "$OUTPUT_DIR/04-aks-clusters.json" 2>&1

# Detailed info for each cluster
echo -e "\n=== Detailed AKS Information ===" >> "$OUTPUT_DIR/04-aks-clusters.txt"
for cluster in $(az aks list --query "[].name" -o tsv); do
    rg=$(az aks list --query "[?name=='$cluster'].resourceGroup" -o tsv)
    echo -e "\n--- Cluster: $cluster (RG: $rg) ---" >> "$OUTPUT_DIR/04-aks-clusters.txt"
    az aks show --name "$cluster" --resource-group "$rg" --output table >> "$OUTPUT_DIR/04-aks-clusters.txt" 2>&1

    # Node pools
    echo -e "\n  Node Pools:" >> "$OUTPUT_DIR/04-aks-clusters.txt"
    az aks nodepool list --cluster-name "$cluster" --resource-group "$rg" --output table >> "$OUTPUT_DIR/04-aks-clusters.txt" 2>&1
done

################################################################################
# 5. Virtual Machines
################################################################################
echo -e "${YELLOW}[5/12] Collecting Virtual Machines...${NC}"

echo "=== Virtual Machines ===" > "$OUTPUT_DIR/05-virtual-machines.txt"
az vm list --output table >> "$OUTPUT_DIR/05-virtual-machines.txt" 2>&1
az vm list --output json > "$OUTPUT_DIR/05-virtual-machines.json" 2>&1

# VM sizes and status
echo -e "\n=== VM Sizes and Power State ===" >> "$OUTPUT_DIR/05-virtual-machines.txt"
az vm list -d --output table >> "$OUTPUT_DIR/05-virtual-machines.txt" 2>&1

################################################################################
# 6. Container Registries (ACR)
################################################################################
echo -e "${YELLOW}[6/12] Collecting Container Registries...${NC}"

echo "=== Azure Container Registries ===" > "$OUTPUT_DIR/06-container-registries.txt"
az acr list --output table >> "$OUTPUT_DIR/06-container-registries.txt" 2>&1
az acr list --output json > "$OUTPUT_DIR/06-container-registries.json" 2>&1

# Repository list for each ACR
echo -e "\n=== ACR Repositories ===" >> "$OUTPUT_DIR/06-container-registries.txt"
for acr in $(az acr list --query "[].name" -o tsv); do
    echo -e "\n--- ACR: $acr ---" >> "$OUTPUT_DIR/06-container-registries.txt"
    az acr repository list --name "$acr" --output table >> "$OUTPUT_DIR/06-container-registries.txt" 2>&1 || echo "  No access or no repositories"
done

################################################################################
# 7. Storage Accounts
################################################################################
echo -e "${YELLOW}[7/12] Collecting Storage Accounts...${NC}"

echo "=== Storage Accounts ===" > "$OUTPUT_DIR/07-storage-accounts.txt"
az storage account list --output table >> "$OUTPUT_DIR/07-storage-accounts.txt" 2>&1
az storage account list --output json > "$OUTPUT_DIR/07-storage-accounts.json" 2>&1

################################################################################
# 8. Networks (VNets, Subnets, NSGs)
################################################################################
echo -e "${YELLOW}[8/12] Collecting Network Resources...${NC}"

echo "=== Virtual Networks ===" > "$OUTPUT_DIR/08-networking.txt"
az network vnet list --output table >> "$OUTPUT_DIR/08-networking.txt" 2>&1
az network vnet list --output json > "$OUTPUT_DIR/08-networking.json" 2>&1

echo -e "\n=== Network Security Groups ===" >> "$OUTPUT_DIR/08-networking.txt"
az network nsg list --output table >> "$OUTPUT_DIR/08-networking.txt" 2>&1

echo -e "\n=== Public IP Addresses ===" >> "$OUTPUT_DIR/08-networking.txt"
az network public-ip list --output table >> "$OUTPUT_DIR/08-networking.txt" 2>&1

echo -e "\n=== Load Balancers ===" >> "$OUTPUT_DIR/08-networking.txt"
az network lb list --output table >> "$OUTPUT_DIR/08-networking.txt" 2>&1

echo -e "\n=== Application Gateways ===" >> "$OUTPUT_DIR/08-networking.txt"
az network application-gateway list --output table >> "$OUTPUT_DIR/08-networking.txt" 2>&1

################################################################################
# 9. Databases
################################################################################
echo -e "${YELLOW}[9/12] Collecting Database Resources...${NC}"

echo "=== SQL Servers ===" > "$OUTPUT_DIR/09-databases.txt"
az sql server list --output table >> "$OUTPUT_DIR/09-databases.txt" 2>&1

echo -e "\n=== SQL Databases ===" >> "$OUTPUT_DIR/09-databases.txt"
for server in $(az sql server list --query "[].name" -o tsv); do
    rg=$(az sql server list --query "[?name=='$server'].resourceGroup" -o tsv)
    echo -e "\n--- Server: $server ---" >> "$OUTPUT_DIR/09-databases.txt"
    az sql db list --server "$server" --resource-group "$rg" --output table >> "$OUTPUT_DIR/09-databases.txt" 2>&1
done

echo -e "\n=== PostgreSQL Servers ===" >> "$OUTPUT_DIR/09-databases.txt"
az postgres server list --output table >> "$OUTPUT_DIR/09-databases.txt" 2>&1

echo -e "\n=== MySQL Servers ===" >> "$OUTPUT_DIR/09-databases.txt"
az mysql server list --output table >> "$OUTPUT_DIR/09-databases.txt" 2>&1

echo -e "\n=== CosmosDB Accounts ===" >> "$OUTPUT_DIR/09-databases.txt"
az cosmosdb list --output table >> "$OUTPUT_DIR/09-databases.txt" 2>&1

################################################################################
# 10. Monitoring and Log Analytics
################################################################################
echo -e "${YELLOW}[10/12] Collecting Monitoring Resources...${NC}"

echo "=== Log Analytics Workspaces ===" > "$OUTPUT_DIR/10-monitoring.txt"
az monitor log-analytics workspace list --output table >> "$OUTPUT_DIR/10-monitoring.txt" 2>&1

echo -e "\n=== Application Insights ===" >> "$OUTPUT_DIR/10-monitoring.txt"
az monitor app-insights component list --output table >> "$OUTPUT_DIR/10-monitoring.txt" 2>&1

echo -e "\n=== Diagnostic Settings ===" >> "$OUTPUT_DIR/10-monitoring.txt"
az monitor diagnostic-settings subscription list --output table >> "$OUTPUT_DIR/10-monitoring.txt" 2>&1

################################################################################
# 11. Key Vaults and Secrets
################################################################################
echo -e "${YELLOW}[11/12] Collecting Key Vaults...${NC}"

echo "=== Key Vaults ===" > "$OUTPUT_DIR/11-key-vaults.txt"
az keyvault list --output table >> "$OUTPUT_DIR/11-key-vaults.txt" 2>&1
az keyvault list --output json > "$OUTPUT_DIR/11-key-vaults.json" 2>&1

# List secrets (names only - reader access)
echo -e "\n=== Key Vault Secrets (Names Only) ===" >> "$OUTPUT_DIR/11-key-vaults.txt"
for kv in $(az keyvault list --query "[].name" -o tsv); do
    echo -e "\n--- Key Vault: $kv ---" >> "$OUTPUT_DIR/11-key-vaults.txt"
    az keyvault secret list --vault-name "$kv" --query "[].name" -o table >> "$OUTPUT_DIR/11-key-vaults.txt" 2>&1 || echo "  No access to secrets"
done

################################################################################
# 12. Cost and Tags Analysis
################################################################################
echo -e "${YELLOW}[12/12] Collecting Cost and Tags Information...${NC}"

echo "=== Resource Tags Analysis ===" > "$OUTPUT_DIR/12-tags-and-costs.txt"
az resource list --query "[].{Name:name, Type:type, Tags:tags}" -o table >> "$OUTPUT_DIR/12-tags-and-costs.txt" 2>&1

echo -e "\n=== Resources Without Tags ===" >> "$OUTPUT_DIR/12-tags-and-costs.txt"
az resource list --query "[?tags==null].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o table >> "$OUTPUT_DIR/12-tags-and-costs.txt" 2>&1

# Cost Management (requires Cost Management Reader role)
echo -e "\n=== Cost Analysis (Last 30 Days) ===" >> "$OUTPUT_DIR/12-tags-and-costs.txt"
START_DATE=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroup type=Dimension \
  --timeframe "Custom" \
  --time-period from="$START_DATE" to="$END_DATE" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output table >> "$OUTPUT_DIR/12-tags-and-costs.txt" 2>&1 || echo "Cost Management data not accessible (requires Cost Management Reader role)"

################################################################################
# Generate Summary Report
################################################################################
echo -e "${YELLOW}Generating Summary Report...${NC}"

cat > "$OUTPUT_DIR/00-SUMMARY.txt" << EOF
===========================================
AZURE RESOURCE INVENTORY SUMMARY
===========================================
Generated: $(date)
Subscription: $SUBSCRIPTION_ID

--- Resource Counts ---
EOF

echo "Resource Groups: $(az group list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Total Resources: $(az resource list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "AKS Clusters: $(az aks list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Virtual Machines: $(az vm list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Container Registries: $(az acr list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Storage Accounts: $(az storage account list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Virtual Networks: $(az network vnet list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"
echo "Key Vaults: $(az keyvault list --query "length([])" -o tsv)" >> "$OUTPUT_DIR/00-SUMMARY.txt"

cat >> "$OUTPUT_DIR/00-SUMMARY.txt" << EOF

--- Top 10 Resource Types ---
EOF

az resource list --query "[].type" -o tsv | sort | uniq -c | sort -rn | head -10 >> "$OUTPUT_DIR/00-SUMMARY.txt"

cat >> "$OUTPUT_DIR/00-SUMMARY.txt" << EOF

--- Files Generated ---
01-account-info.txt          - Account and subscription details
02-resource-groups.txt       - All resource groups
03-all-resources.txt         - Complete resource inventory
04-aks-clusters.txt          - Kubernetes clusters and node pools
05-virtual-machines.txt      - Virtual machines and sizes
06-container-registries.txt  - Container registries and repositories
07-storage-accounts.txt      - Storage accounts
08-networking.txt            - VNets, NSGs, load balancers
09-databases.txt             - SQL, PostgreSQL, MySQL, CosmosDB
10-monitoring.txt            - Log Analytics, App Insights
11-key-vaults.txt            - Key vaults and secret names
12-tags-and-costs.txt        - Tags analysis and cost data

All data is also available in JSON format where applicable.

===========================================
EOF

################################################################################
# Completion
################################################################################
echo -e "${GREEN}✓ Inventory Complete!${NC}"
echo -e "${BLUE}Results saved to: $OUTPUT_DIR${NC}"
echo -e "${BLUE}View summary: cat $OUTPUT_DIR/00-SUMMARY.txt${NC}"

# Create a tarball
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
echo -e "${GREEN}✓ Archive created: $OUTPUT_DIR.tar.gz${NC}"

exit 0

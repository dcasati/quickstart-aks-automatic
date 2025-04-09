# Quickstart: AKS with Automatic SKU Upgrade

This guide sets up an AKS cluster with the automatic node SKU upgrade preview feature enabled, deploys a sample app, and shows how to clean up the resources afterward.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- AKS CLI extension: `aks-preview`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Enable the AKS Automatic SKU Upgrade Feature

```bash
az extension update --name aks-preview

az feature register --namespace Microsoft.ContainerService --name AutomaticSKUPreview

az provider register --namespace Microsoft.ContainerService
```

Note: It may take several minutes for the feature registration to complete.

## Deploy the AKS Cluster

```bash
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TENANT_ID=$(az account show --query tenantId -o tsv)
export RG=rg-aks-automatic
export LOCATION=westus3
export CLUSTER_NAME=aks-automatic

az group create --name ${RG} --location ${LOCATION}
az deployment group create \
    --resource-group ${RG} \
    --template-file main.bicep \
    --parameters \
        clusterName="${CLUSTER_NAME}" \
        location="${LOCATION}"
```

## Connecto to the cluster

### 1. Get the AKS cluster resource ID
CLUSTER_ID=$(az aks show -g rg-aks-automatic -n aks-automatic --query id -o tsv)
MY_USERNAME=admin@contoso.onmicrosoft.com

### 2. Assign Kubernetes Cluster Admin RBAC Role
az role assignment create \
  --assignee "${MY_USER_NAME}$" \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope "$CLUSTER_ID"

### 3. Assign Cluster User Role (to get kubeconfig)
az role assignment create \
  --assignee "${MY_USER_NAME}" \
  --role "Azure Kubernetes Service Cluster User" \
  --scope "$CLUSTER_ID"

Get the cluster credentials

```bash
az aks get-credentials --resource-group ${RG} --name ${CLUSTER_NAME}
```

In codespaces:

```bash
kubelogin convert-kubeconfig -l azurecli
```

## Deploy the Application

```bash
kubectl create ns aks-store-demo

kubectl apply -n aks-store-demo -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-ingress-quickstart.yaml
```

## Test the Application

```bash
kubectl get pods -n aks-store-demo

kubectl get ingress store-front -n aks-store-demo --watch
```

Wait for the external IP to appear in the `ADDRESS` column to access the application.

## Delete the Cluster

```bash
az group delete --name myResourceGroup --yes --no-wait
```

This will delete all resources in the specified resource group.

## GitHub Actions Integration

### Step 1: Fork the Repository

Fork this repo to your GitHub account.

### Step 2: Create a User-Assigned Managed Identity

```bash
MI_NAME="github-actions-identity"
RESOURCE_GROUP_MI="rg-github-actions-identity"

az group create --name "$RESOURCE_GROUP_MI" --location "$LOCATION"

az identity create \
  --name "$MI_NAME" \
  --resource-group "$RESOURCE_GROUP_MI" \
  --location "$LOCATION"
```

### Step 3: Save Identity Info

```bash
CLIENT_ID=$(az identity show -g "$RESOURCE_GROUP_MI" -n "$MI_NAME" --query clientId -o tsv)
```

### Step 4: Assign Role

```bash
MI_PRINCIPAL_ID=$(az identity show -g "$RESOURCE_GROUP_MI" -n "$MI_NAME" --query principalId -o tsv)

az role assignment create \
  --assignee-object-id "$MI_PRINCIPAL_ID" \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG
```

### Step 5: Create Federated Identity Credential

```bash
GITHUB_ORG="dcasati"
REPO="quickstart-aks-automatic"

az identity federated-credential create \
  --name github-actions \
  --identity-name "$MI_NAME" \
  --resource-group "$RESOURCE_GROUP_MI" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$REPO:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"
```

### Step 6: Create GitHub Secrets

Go to your GitHub repo:

**Settings → Secrets and variables → Actions → New repository secret**

Create these secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

```bash
echo AZURE_CLIENT_ID: $CLIENT_ID
echo AZURE_TENANT_ID: $TENANT_ID
echo AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID
```

Use the values from Step 3.
#!/bin/env bash 
#
set -eoux

# Configuration variables
RESOURCE_GROUP_NAME="myResourceGroup"
LOCATION="westus3"
DEPLOYMENT_NAME="aks-arm-deployment-$(date +%Y%m%d-%H%M%S)"
PARAMETERS_FILE="parameters.json"

az group create -n ${RESOURCE_GROUP_NAME} -l ${LOCATION}
# Deploy using variables
az deployment group create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$DEPLOYMENT_NAME" \
  --template-file aks-automatic.json \
  --parameters location="$LOCATION" \
  --output table | tee deployment.log 2>&1 &

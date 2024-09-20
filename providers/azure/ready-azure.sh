#!/bin/sh

export AZURE_SUBSCRIPTION_ID=$(az account show --query id)
servicePrincipal=$(az ad sp create-for-rbac --role contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}")
export AZURE_CLIENT_ID=$(echo $servicePrincipal | jq '.appId')
export AZURE_CLIENT_SECRET=$(echo $servicePrincipal | jq '.password')
export AZURE_TENANT_ID=$(echo $servicePrincipal | jq '.tenant')
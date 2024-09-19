# Azure process steps
[Azure book](https://cluster-api.sigs.k8s.io/user/quick-start.html)

## Do this once 
Service Principal is reusable

1. Export Azure subscription ID

1. Create an Service Principal (SP) 
    `az ad sp create-for-rbac --role contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}"`
    ```
{
  "appId": "78c4361a-86ca-4f9b-8af7-0524c827b883",
  "displayName": "azure-cli-2024-09-19-13-59-49",
  "password": "qEA8Q~5aCgGl93mqrenofsYOp_AfCqwXq~awscmN",
  "tenant": "fcf34994-aac4-4462-afaa-d83f87c5f51d"
}
    ```

## 
1. Export environment variables
    ```
    # Insert details from azure service principal
    export AZURE_TENANT_ID="fcf34994-aac4-4462-afaa-d83f87c5f51d"
    export AZURE_CLIENT_ID="78c4361a-86ca-4f9b-8af7-0524c827b883"
    export AZURE_CLIENT_ID_USER_ASSIGNED_IDENTITY=$AZURE_CLIENT_ID 
    export AZURE_CLIENT_SECRET="qEA8Q~5aCgGl93mqrenofsYOp_AfCqwXq~awscmN"
    export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
    export CLUSTER_IDENTITY_NAME="cluster-identity"
    export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"

    export AZURE_LOCATION="eastus"
    export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_D2s_v3"
    export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v3"
    export AZURE_RESOURCE_GROUP="mak3r-capi-rg"
    ```
1. Generate a secret
    `kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"`
1. Finally, initialize the management cluster
    `clusterctl init --infrastructure azure`
1. Generate cluster configuration
    ```
    clusterctl generate cluster demo-azure-06 \
  --infrastructure azure \
  --kubernetes-version v1.30.3 \
  --control-plane-machine-count=3 \
  --worker-machine-count=2\
  > demo-azure-06.yaml
    ```
1. Modify yaml
    `yq -i "with(. | select(.kind == \"AzureClusterIdentity\"); .spec.type |= \"ServicePrincipal\" | .spec.clientSecret.name |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAME}\" | .spec.clientSecret.namespace |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}\")" demo-azure-06.yaml`
1. Modify yaml (AzureMachineTemplate.spec.template.spec.userAssignedIdentities.providerID) with correct azure resource group
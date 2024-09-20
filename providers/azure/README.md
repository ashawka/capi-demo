# Azure process steps
[Azure book](https://cluster-api.sigs.k8s.io/user/quick-start.html)

## Setup environment 
Service Principal is reusable for multiple clusters

1. Export Azure subscription ID
    `export AZURE_SUBSCRIPTION_ID=$(az account show --query id)

1. Create an Service Principal (SP) 
    `servicePrincipal=$(az ad sp create-for-rbac --role contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}")`

1. Read out secret and SP details into necessary environment variables
    ```
    export AZURE_CLIENT_ID=$(echo $servicePrincipal | jq '.appId')
    export AZURE_CLIENT_SECRET=$(echo $servicePrincipal | jq '.password')
    export AZURE_TENANT_ID=$(echo $servicePrincipal | jq '.tenant')
    ```
1. Create a resource group or use existing rg in Azure portal
1. Add service principle user/role to resource group in Azure portal
1. Create a namespace in the management cluster for this new Azure cluster if it doesn't already exist. Alternatively you can use the `default` namespace. 
## 
1. Export environment variables
    ```
    export AZURE_CLIENT_ID_USER_ASSIGNED_IDENTITY=$AZURE_CLIENT_ID 
    export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
    export CLUSTER_IDENTITY_NAME="cluster-identity"
    export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="capz-demo" # Namespace created above or default

    export AZURE_LOCATION="eastus"
    export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_D2s_v3"
    export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v3"
    export AZURE_RESOURCE_GROUP="mak3r-capi-rg"
    ```
1. Generate a secret
    `kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"`
1. Finally, initialize the management cluster (This only needs to be done once per management cluster)
    `clusterctl init --infrastructure azure`
1. Generate cluster configuration
    ```
    clusterctl generate cluster demo-azure-08 \
  --infrastructure azure \
  --kubernetes-version v1.30.3 \
  --control-plane-machine-count=3 \
  --worker-machine-count=2\
  > demo-azure-08.yaml
    ```
1. Modify yaml
    `yq -i "with(. | select(.kind == \"AzureClusterIdentity\"); .spec.type |= \"ServicePrincipal\" | .spec.clientSecret.name |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAME}\" | .spec.clientSecret.namespace |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}\")" demo-azure-06.yaml`
1. Modify yaml (AzureMachineTemplate.spec.template.spec.userAssignedIdentities.providerID) with correct azure resource group
1. `kubectl apply -f <output_cluster_config.yaml>`
1. Get the kubeconfig from this cluster for use in the next steps
    `clusterctl get kubeconfig <cluster_name>`

## Add the cloud provider
`helm install --kubeconfig=./demo-azure-08.kubeconfig --repo https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/helm/repo cloud-provider-azure --generate-name --set infra.clusterName=demo-azure-08 --set cloudControllerManager.clusterCIDR="192.168.0.0/16"`

## Add a CNI
`helm repo add projectcalico https://docs.tigera.io/calico/charts --kubeconfig=./demo-azure-08.kubeconfig && \
helm install calico projectcalico/tigera-operator --kubeconfig=./demo-azure-08.kubeconfig -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addons/calico/values.yaml --namespace tigera-operator --create-namespace`

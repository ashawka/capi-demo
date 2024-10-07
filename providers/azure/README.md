# Azure process steps
[Azure book](https://cluster-api.sigs.k8s.io/user/quick-start.html)

## Setup environment
Service Principal is reusable for multiple clusters

1. Export Azure subscription ID
    `export AZURE_SUBSCRIPTION_ID=$(az account show --query id | sed  s/\"//g)`

1. Create an Service Principal (SP) 
    `az ad sp create-for-rbac --role contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}" > servicePrincipal.pvt`

1. Read out secret and SP details into necessary environment variables
    ```
    export AZURE_CLIENT_ID=$(cat servicePrincipal.pvt | jq -r '.appId')
    export AZURE_CLIENT_SECRET=$(cat servicePrincipal.pvt | jq -r '.password')
    export AZURE_TENANT_ID=$(cat servicePrincipal.pvt | jq -r '.tenant')
    ```
1. Create a resource group or use existing rg in Azure portal
1. Add service principle user/role to resource group in Azure portal
 
## 
1. Export environment variables
    ```
    export AZURE_CLIENT_ID_USER_ASSIGNED_IDENTITY=$AZURE_CLIENT_ID 
    export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
    export CLUSTER_IDENTITY_NAME="cluster-identity"
    export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default" 

    export AZURE_LOCATION="eastus"
    export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_D2s_v2"
    export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v2"
    export AZURE_RESOURCE_GROUP="mak3r-capi-rg"
    export EXP_MACHINE_POOL=true
    ```
1. Generate a secret
    `kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"`
1. Finally, initialize the management cluster (This only needs to be done once per management cluster)
    `clusterctl init --infrastructure azure`

## Create cluster from toilet
1. Generate environment variables
    ```
    export CLUSTER_NAME=aks-frm-tmplt-01
    export KUBERNETES_VERSION=v1.30.3
    export CONTROL_PLANE_MACHINE_COUNT=3
    export WORKER_MACHINE_COUNT=2
    ```
1. Create cluster config from clusterctl
    `clusterctl generate cluster $CLUSTER_NAME --from ./providers/azure/azure-aks-mmp.yaml --flavor aks > "$CLUSTER_NAME".yaml`

## Create cluster config from clusterctl
1. Generate cluster configuration
    ```
    clusterctl generate cluster demo-azure-12 \
    --kubernetes-version v1.30.3 \
    --worker-machine-count=2 \
    --flavor aks \
    > demo-azure-12.yaml
    ```
1. Modify yaml
    `yq -i "with(. | select(.kind == \"AzureClusterIdentity\"); .spec.type |= \"ServicePrincipal\" | .spec.clientSecret.name |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAME}\" | .spec.clientSecret.namespace |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}\")" demo-azure-09.yaml`
1. Modify yaml (AzureMachineTemplate.spec.template.spec.userAssignedIdentities.providerID) with correct azure resource group
1. `kubectl apply -f <output_cluster_config.yaml>`
1. Get the kubeconfig from this cluster for use in the next steps
    `clusterctl get kubeconfig <cluster_name>`

## Add the cloud provider
`helm install --kubeconfig=./demo-azure-08.kubeconfig --repo https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/helm/repo cloud-provider-azure --generate-name --set infra.clusterName=demo-azure-08 --set cloudControllerManager.clusterCIDR="192.168.0.0/16"`

## Add a CNI
`helm repo add projectcalico https://docs.tigera.io/calico/charts --kubeconfig=./demo-azure-08.kubeconfig && \
helm install calico projectcalico/tigera-operator --kubeconfig=./demo-azure-08.kubeconfig -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addons/calico/values.yaml --namespace tigera-operator --create-namespace`


## From template
    ```
    clusterctl generate cluster demo-azure-11 \
    --from ./providers/azure/azure-aks-mmp.yaml \
    > demo-azure-11.yaml
    ```

=====================

## From AKS ASO template
1. Install ASO service operator
    ```
    helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
    helm upgrade --install aso2 aso2/azure-service-operator \
        --create-namespace \
        --namespace=azureserviceoperator-system \
        --set crdPattern='resources.azure.com/*;containerservice.azure.com/*;keyvault.azure.com/*;managedidentity.azure.com/*;eventhub.azure.com/*'
    ```
1. Export Azure subscription ID
    `export AZURE_SUBSCRIPTION_ID=$(az account show --query id | sed  s/\"//g)`

1. Create an Service Principal (SP) 
    `az ad sp create-for-rbac -n azure-service-operator --role contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}" > servicePrincipal.pvt`

1. Read out SP details into necessary environment variables
    ```
    export AZURE_CLIENT_ID=$(cat servicePrincipal.pvt | jq -r '.appId')
    export AZURE_CLIENT_SECRET=$(cat servicePrincipal.pvt | jq -r '.password')
    export AZURE_TENANT_ID=$(cat servicePrincipal.pvt | jq -r '.tenant')
    ```

1. Export configuration data
    ```
    export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v2"
    export CLUSTER_NAME=aks-aso-frm-tmplt
    export KUBERNETES_VERSION=v1.30.3
    export ASO_CREDENTIAL_SECRET_NAME=aso-credential
    export AZURE_LOCATION=eastus
    ```

1. Create aso credential secret
    ```
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Secret
    metadata:
    name: aso-credential
    namespace: default
    stringData:
    AZURE_SUBSCRIPTION_ID: "$AZURE_SUBSCRIPTION_ID"
    AZURE_TENANT_ID: "$AZURE_TENANT_ID"
    AZURE_CLIENT_ID: "$AZURE_CLIENT_ID"
    AZURE_CLIENT_SECRET: "$AZURE_CLIENT_SECRET"
    EOF
    ```

1. Generate cluster yaml from template
    ```
    clusterctl generate cluster $CLUSTER_NAME \
    --from ./providers/azure/cluster-template-aks-aso.yaml \
    > "$CLUSTER_NAME".yaml
    ```

1. Apply cluster configuration
    `kubectl apply -f "$CLUSTER_NAME".yaml`

## TEST
1. Test ASO provider by creating a resource group through kubernetes
    `kubectl apply -f providers/azure/aso-resource-group.yaml`
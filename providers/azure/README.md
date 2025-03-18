# Azure CAPZ for managed AKS steps

[Azure book](https://capz.sigs.k8s.io/managed/managedcluster)

## Requirements

* Rancher Or Rancher Prime >=v2.9.x
* Turtles operator installed in Rancher Local Cluster
* `azure-cli` is installed
* `kubectl` is installed

---

### Initial setup

1. Install Rancher Turtles
(<https://turtles.docs.rancher.com/turtles/stable/en/tutorials/quickstart.html>)

2. Create an Azure CAPI Provider, using the referenced CAPIProvider.yaml file
    `kubectl --kubeconfig <config-file.yaml> apply -f CAPIProvider.yaml`
    
    Wait until you find resource available and ready in rancher UI under More Resources > turtles-capi.cattle.io > CAPIProviders

    ![Azure-CAPI-Provider_installed](image.png)
    The installation may take a few minutes and, when it finishes, you will be able to see the following new deployments in the cluster

   `kubectl --kubeconfig <config-file.yaml> get deployment -n capi-system`


---

### Prepare your enviroment

1. Setup environment variables in your working shell


1.1 Export Azure subscription ID

    `export AZURE_SUBSCRIPTION_ID=$(az account show --query id | sed  s/\"//g)`

1.2 Export cluster variable details

    `export CLUSTER_NAME="your-cluster-name"`
    `export WORKER_MACHINE_COUNT=<number-of-worker-nodes>`
    `export KUBERNETES_VERSION="v1.xx.x"`
    `export EXP_MACHINE_POOL=true`
    `export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"`
    `export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"`
    `export CLUSTER_IDENTITY_NAME="cluster-identity"`

1.3 Export Azure region values

During my tests I used eastus & uaenorth
Douple check the machine type because it is different per az region.

During my test machine type is part of the cluster template.

    `export AZURE_LOCATION="region-name"`
    `export AZURE_NODE_MACHINE_TYPE="Standard_D2s_v3"`
    `export AZURE_RESOURCE_GROUP="${CLUSTER_NAME}"`


2. Create an Service Principal (SP)
 from azure-cli create a Service Principal. 
 This Service Principle is reusable for multiple clusters

    `az ad sp create-for-rbac --role Contributor --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}" --sdk-auth > sp.json`

3. Read out secret and SP details into necessary environment variables

    `export AZURE_CLIENT_ID=$(cat sp.json | jq -r '.appId')`
    `export AZURE_CLIENT_SECRET=$(cat sp.json | jq -r '.password')`
    `export AZURE_TENANT_ID=$(cat sp.json | jq -r '.tenant')`


4. In Rancher Management Server (CAPI/turtles managemer), generate a secret. 

    `kubectl --kubeconfig <config-file.yaml> create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"`

---

### CAPZ managed AKS cluster deployment

1. Substitute the variables in the cluster template with the current envirnment variables you set earlier and then use the template to create the cluster. 

    `envsubst < <cluster-template>.yaml | kubectl --kubeconfig <config-file.yaml> apply -f -`

2. To import the newly created CAPI cluster, you need to run the labeling command in the Rancher Management cluster (local) cluster. 

    `kubectl --kubeconfig <config-file.yaml> label cluster.cluster.x-k8s.io -n default $CLUSTER_NAME cluster-api.cattle.io/rancher-auto-import=true`

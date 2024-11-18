# capi-demo
CAPI Demo on Rancher Manager using Turtles

## Requirements 

* Rancher >=v2.9.x or Rancher Prime >= v3.0 installed
* Turtles operator installed in Rancher Local Cluster
* `clusterctl` is installed 
* `clusterawsadm` is installed 

## AWS infra with RKE2 k8s - Steps

### Build an AMI
Original docs here: https://github.com/rancher/cluster-api-provider-rke2/blob/main/image-builder/README.md

#### Prerequisites
* Hashicorp packer
* AWS packer plugin 

    `packer plugins install github.com/hashicorp/amazon` 

#### Build AMI
1. Checkout the https://github.com/rancher/cluster-api-provider-rke2/tree/main project locally
1. cd into the image-builder directory
1. edit aws/opensuse-leap-156.json with valid existing AMI
1. build command uses 156 not 155 (which is in the docs)

---

### Initial setup

1. Install Rancher Turtles
1. Source some bash functions for the next steps

    `source providers/aws/ready-aws.sh`
1. Prep env variables

    `prep_env [your-aws-ssh-key-name]`
1. Setup IAM profile

    `clusterawsadm bootstrap iam create-cloudformation-stack`
1. Install the capa-system namespace

    `kubectl apply -f providers/aws/ns.yaml`
1. Generate the secret

    `generate_secret`

1. Install the Infrastucture provider

    `kubectl apply -f providers/aws/InfrastructureProviderAWS.yaml`

### Create a cluster (requires completion of Initial Setup)

1. Source some bash functions for the next steps

    `source providers/aws/ready-aws.sh`
1. Prep env variables 
    * NOTE: Do not include `.pem` extension of the key name

    `prep_env [your-aws-ssh-key-name]`
1. Create a cluster yaml configuration
    * NOTE: This creates the cluster configuration and applies it.

    `create_cluster [cluster-name]`

## Debugging

If things don't go as expected, look at the capa-controller-manager pod logs. From there, hopefully you can work your way through other resources to figure out what is missing/misconfigured/etc.

## Cleanup

1. for each cluster created `kubectl delete -f <cluster_name>.yaml`
1. Remove `<cluster>.yaml` files from the project.
1. Remove namespaces created with clusters
1. Delete the aws secret `kubectl delete secret aws-variables -n capa-system`

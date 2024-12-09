# Preparation Steps

## Create two Rancher environments

* Use two clones of [terraform-rancher](https://github.com/mak3r/terraform-rancher) project

### Clone 1 - PROD

1. `make RANCHER_SUBDOMAIN="non-prod" ADMIN_SECRET="jkl99JKL88" LETS_ENCRYPT_USER="mark.abrams@suse.com" k3s_rancher`
1. `make turtles_install`
1. modify kubeconfig - set name, context, and user

### Clone 2 - NON PROD

1. `make RANCHER_SUBDOMAIN="prod" ADMIN_SECRET="jkl99JKL88" LETS_ENCRYPT_USER="mark.abrams@suse.com" k3s_rancher`
1. `make turtles_install`
1. modify kubeconfig - set name, context, and user

## Create one master kubeconfig for context switching

* NOTE: Be sure to change the default values in each kubconfig or else this will not work

1. From the project location where terraform rancher `non-prod` was built run this script

```bash
#!/bin/bash
source ../capi-demo/multi-rancher/kubeconfig-helper-functions.sh
kubeconfig_replace kubeconfig clusters[0].name "non-prod"
kubeconfig_replace kubeconfig contexts[0].name "non-prod"
kubeconfig_replace kubeconfig contexts[0].context.cluster "non-prod"
kubeconfig_replace kubeconfig contexts[0].context.user "non-prod-admin"
kubeconfig_replace kubeconfig contexts[0].context.name "non-prod"
kubeconfig_replace kubeconfig current-context "non-prod"
kubeconfig_replace kubeconfig users[0].name "non-prod-admin"
```

1. From the project location where terraform rancher `prod` was built run this script

```bash
#!/bin/bash
source ../capi-demo/multi-rancher/kubeconfig-helper-functions.sh
kubeconfig_replace kubeconfig clusters[0].name "prod"
kubeconfig_replace kubeconfig contexts[0].name "prod"
kubeconfig_replace kubeconfig contexts[0].context.cluster "prod"
kubeconfig_replace kubeconfig contexts[0].context.user "prod-admin"
kubeconfig_replace kubeconfig contexts[0].context.name "prod"
kubeconfig_replace kubeconfig current-context "prod"
kubeconfig_replace kubeconfig users[0].name "prod-admin"
```

1. `export KUBECONFIG="/home/suse-mak3r/projects/terraform-rancher/kubeconfig:/home/suse-mak3r/projects/terraform-rancher-02/kubeconfig"`
1. `kubectl config view --merge --flatten > ~/.kube/config`

1. Use git clone of [capi-demo](https://github.com/mak3r/capi-demo) project
1. Create an AMI if there is not already a working AMI
1. `cd ~/projects/terraform-rancher-02`
1. Switch context to the `non-prod` cluster `kubectl config use-context non-prod`

### Install turtles in the non prod env

1. Switch to the terraform-rancher project
1. `make turtles_install`

### Install aws provider in the non prod env

1. Switch to the capi-demo project `cd ../capi-demo`
1. `source providers/aws/ready-aws.sh`
1. `prep_env mak3r-suse-key-pair-2`
1. `clusterawsadm bootstrap iam create-cloudformation-stack`
1. `kubectl apply -f providers/aws/ns.yaml`
1. `generate_secret`
1. `kubectl apply -f providers/aws/InfrastructureProviderAWS.yaml`

### Switch to the prod environment

1. `cd ~/projects/terraform-rancher`
1. Switch context to the `prod` cluster `kubectl config use-context prod`

### Install turtles in the prod env

1. Switch to the terraform-rancher-02 project
1. `make turtles_install`

### Install aws provider in the prod env

1. Switch to the capi-demo project `cd ../capi-demo`
1. `source providers/aws/ready-aws.sh`
1. `prep_env mak3r-suse-key-pair-2`
1. `clusterawsadm bootstrap iam create-cloudformation-stack`
1. `kubectl apply -f providers/aws/ns.yaml`
1. `generate_secret`
1. `kubectl apply -f providers/aws/InfrastructureProviderAWS.yaml`

### If Autoscaling Demo is required

1. Switch to the capi-demo project `cd ../capi-demo`
1. `source CAPI/ready-autoscaler.sh`
1. `install_autoscaler`
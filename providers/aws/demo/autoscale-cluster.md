# Create autoscaling cluster

## Assumptions

* Rancher instance >v2.9.2
* Turtles >v0.11.0
* CAPI AWS provider installed
* kubeconfig context `non-prod` points to desired Rancher instance
* Any other [preparation steps](./preparation.md) needed have been completed

## Create a cluster named `blue` in namespace `dev-team-blue`

1. `kubectl config use-context non-prod`
1. `source providers/aws/ready-aws.sh`
1. `prep_env mak3r-suse-key-pair-2`
1. `create_autoscale_cluster_in_namespace blue dev-team-blue`
1. Watch for cluster to get created. `watch kubectl get cluster -n dev-team-blue`

### Get kubeconfig from downstream cluster `blue`. Make it usable

#### Assumptions

* The downstream cluster is provisioned

1. `clusterctl get kubeconfig -n dev-team-blue blue > kubeconfig-blue.yaml`
1. `export KUBECONFIG=~/.kube/config.bak:./kubeconfig-blue.yaml`
1. `kubectl config view --flatten --merge > ~/.kube/new-config`
1. `unset KUBECONFIG`
1. `mv ~/.kube/new-config ~/.kube/config`
1. Check that all contexts are available now `kubectl config get-contexts`

### Setup autoscaler (requires kubeconfig from Rancher and downstream cluster)

#### Assumptions

* Rancher `local` kubeconfig is installed as a secret per the [autoscaler argument](../CAPI/ClusterAutoscaler.yaml) `--cloud-config=/mnt/kubeconfig-cp/kubeconfig`
* Downstream `blue` kubeconfig is installed as a secret per the [autoscaler argument](../CAPI/ClusterAutoscaler.yaml) `--kubeconfig=/mnt/kubeconfig-downstream/kubeconfig`

1. `kubectl create secret generic -n kube-system --from-file kubeconfig-blue.yaml kubeconfig-blue`
1. `export CLUSTER_NAME=blue`
1. `source CAPI/ready-autoscaler.sh`
1. `install_autoscaler`
1. Verify the autoscaler came up `kubectl get pods -n kube-system`

### Load test autoscaling

#### Assumptions

* The `blue` cluster is provisioned
* The `blue` cluster kubeconfig is available as `blue-admin@blue` context
* The CAPI autoscaler is configured and running in the `local` cluster

1. `kubectl config use-context blue-admin@blue`
1. `kubectl apply -f CAPI/load-test.yaml`

## Cleanup

### Remove old autoscaler and old autoscale cluster

1. `kubectl delete -f blue-non-prod.yaml`
1. `kubectl delete -n kube-system deployment cluster-autoscaler`
1. `source CAPI/ready-autoscaler.sh`
1. `remove_autoscaler`
1. `kubectl delete secret kubeconfig-blue -n kube-system`
1. Delete artifacts from the file system `blue-non-prod.yaml` and `kubeconfig-blue.yaml`
1. Clean up `~/.kube/config` as needed - remove blue context and kubeconfig data
# Create a fixed node scale cluster using fleet

## Assumptions

* Rancher instance >v2.9.2
* Turtles >v0.11.0
* CAPI AWS provider installed
* kubeconfig context `non-prod` points to desired Rancher instance
* Any other [preparation steps](./preparation.md) needed have been completed

## Steps

1. Switch to non-prod `kubectl config use-context non-prod`
1. `kubectl apply -f fleet/repo-example.yaml`
1. Import all clusters in the default namespace `kubectl label namespace default cluster-api.cattle.io/rancher-auto-import=true`
1. Scale cluster by changing the scale of `fleet/aws/small/capi-ec2-sm.yaml` and commiting the change to github
    * Find `MachineDeployment` object
    * Update `replicas:` to `3`
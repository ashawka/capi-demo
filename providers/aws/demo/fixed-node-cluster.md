# Fixed node size cluster

## Assumptions

* Rancher instance >v2.9.2
* Turtles >v0.11.0
* CAPI AWS provider installed
* kubeconfig context `non-prod` points to desired Rancher instance
* Any other [preparation steps](./preparation.md) needed have been completed

## Steps

1. Switch context to the `non-prod` cluster `kubectl config use-context non-prod`
1. `source providers/aws/ready-aws.sh`
1. `prep_env mak3r-suse-key-pair-2`
1. `create_cluster_in_namespace ci-cd dev-team-blue`

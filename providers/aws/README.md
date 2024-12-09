# CAPI demos with CAPA (AWS)

## Prepare your environment

[Preparation](./preparation.md)

### Methods of interest in `ready_aws.sh`

* `prep_env`
* `generate_secret`
* `create_cluster_in_namespace`
* `import_clusters_in_namespace`

## Cluster demo options

* [CAPI Autoscaling](./demo/autoscale-cluster.md)
* [Fixed node scale](./demo/fixed-node-cluster.md)
* [Fleet fixed node scale automation](./demo/fleet-fixed-node-cluster.md)
* Fleet CAPI autoscaling should be possible but is not yet setup
* ClusterClass is not yet setup

---

## Known issues

* Multiple clusters created from the same config file compete for underlying resources
  * Check configmaps `cloud-controller-manager-addon`
  * Check configmaps `aws-ebs-csi-driver-addon`
  * Most likely adding the cluster name as a prefix for competing resources will resolve the issue

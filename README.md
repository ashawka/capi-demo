# capi-demo
CAPI Demo on Rancher Manager using Turtles

## Requirements 

* Rancher >=v2.9.x or Rancher Prime >= v3.0 installed
* Turtles operator installed in Rancher Local Cluster
* `clusterctl` is installed 
* `clusterawsadm` is installed 

## AWS infra with RKE2 k8s - Steps

1. Install Rancher Turtles
1. Source some bash functions for the next steps

    `source providers/aws/ready-aws.sh`
1. Prep env variables

    `prep_env [your-aws-ssh-key-name]`
<!-- 1. Setup IAM profile

    `clusterawsadm bootstrap iam create-cloudformation-stack` -->
1. Install the capa-system namespace

    `kubectl apply -f providers/aws/ns.yaml`
1. Generate the secret

    `generate_secret`
1. Install a CAPI provider

    `kubectl apply -f providers/aws/CAPIProvider.yaml`
1. Install the Infrastucture provider

    `kubectl apply -f providers/aws/InfrastructureProviderAWS.yaml`
1. Create a cluster yaml configuration

    `create_cluster [cluster-name] > [cluster-name].yaml`
1. Manually edit the `[cluster-name].yaml` 

    * spec.registrationMethod can be one of [internal-first | internal-only-ips | external-only-ips | address | control-plane-endpoint]
    * Add the `registrationMethod: "control-plane-endpoint"` to the RKE2ControlPlane `spec`
1. Apply the cluster config

    `kubectl apply -f [cluster-name].yaml`

## Debugging
If things don't go as expected, look at the capa-controller-manager pod logs. From there, hopefully you can work your way through other resources to figure out what is missing/misconfigured/etc.


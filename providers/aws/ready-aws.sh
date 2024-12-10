#!/bin/sh

# It would be nice to add some checks to see if the prerequisites are met
# and also if the resources already exist in the management cluster


prep_env() {
    KEY_PAIR='default'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default' will be used as the AWS_SSH_KEY_NAME."
    else
        KEY_PAIR=$1
    fi

    export AWS_REGION=us-east-1
    export AWS_SSH_KEY_NAME=$KEY_PAIR
    # "Name": "openSUSE-Leap-15.6-HVM-x86_64-prod-xkhy6u6pewna4"
    # NOTE: Be sure to subscribe to use this AMI or change it to use your own
    # subscribe url: https://aws.amazon.com/marketplace/server/procurement?productId=prod-xkhy6u6pewna4
    # owner-id: 679593333241
    # export AWS_AMI_ID="ami-019aa0ac90f597bf5"

    # "Name": "Ubuntu Server 22.04 LTS (HVM), SSD Volume"
    # export AWS_AMI_ID="ami-0a0e5d9c7acc336f1"


    # Custom AMIs
    # aws ec2 describe-images --owners "488083572758" --filters "Name=name,Values=capa*" "Name=architecture,Values=arm64,x86_64"

    # x86_64 AMI
    # Airgapped AMI
    # "Name": "amazon-ebs.openSUSE-leap-15.6-rke2"
    # us-east-1: ami-04418d0a73ebfbb4a
    # us-west-1: ami-061e0d437b327464e
    ## uncomment the following lines to use the x86_64 AMI
    # export AWS_AMI_ID="ami-04418d0a73ebfbb4a"
    # export AWS_CONTROL_PLANE_MACHINE_TYPE=t3a.large
    # export AWS_NODE_MACHINE_TYPE=t3a.large

    # Arm64 AMI
    # "Name": capa-ami-openSUSE-leap-15.6-arm64-1.30.7-rke2r1-1733863209
    # "AMI": ami-02c1d58242ed9e995
    # "Owner id": "488083572758"
    # "Name": "amazon-ebs.openSUSE-leap-15.6-arm64"
    # us-east-1: ami-02c1d58242ed9e995
    # us-west-1: ami-0f0e7af7d5dffddca
    ## uncomment the following lines to use the arm64 AMI
    export AWS_AMI_ID="ami-02c1d58242ed9e995"
    export AWS_CONTROL_PLANE_MACHINE_TYPE=a1.large
    export AWS_NODE_MACHINE_TYPE=a1.large

    # Auto Scaling Group
    export AWS_ASG_NAME=Mak3rCAPIAutoScalingDemo

    # Select instance types
    export RKE2_VERSION=v1.30.3+rke2r1
    export CONTROL_PLANE_MACHINE_COUNT=1
    export WORKER_MACHINE_COUNT=1
    export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
}

generate_secret() {
    kubectl apply -f -<<EOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-variables
  namespace: capa-system
type: Opaque
stringData:
  AWS_B64ENCODED_CREDENTIALS: $AWS_B64ENCODED_CREDENTIALS
  ExternalResourceGC: "true"
EOF
}

generate_hpa() {
    kubectl apply -f -<<EOF
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: $CLUSTER_NAME-hpa
  namespace: kube-system                                  # Assuming cluster autoscaler is running in kube-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $CLUSTER_NAME-md-0                                      # Ensure this matches your deployment's name
  minReplicas: 2                                          # Minimum nodes
  maxReplicas: 5                                          # Maximum nodes
  targetCPUUtilizationPercentage: 80                      # Adjust thresholds as necessary for your needs
EOF
}

init_aws() {
    #clusterctl init --infrastructure aws
    prep_env
    generate_secret
}

create_cluster() {
    NAME='default-cluster'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default-cluster' will be used as the cluster name."
    else
        NAME=$1
    fi

    clusterctl generate cluster $NAME \
        --from https://github.com/mak3r/capi-demo/blob/main/providers/aws/cluster-template.yaml \
        > $NAME.yaml
    kubectl apply -f $NAME.yaml
}

# Create a cluster in a specific namespace
# Name then namespace as arguments
create_cluster_in_namespace() {
    NAME='default-cluster'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default-cluster' will be used as the cluster name."
    else
        NAME=$1
    fi

    NAMESPACE='default'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default' will be used as the cluster namespace."
    else
        NAMESPACE=$2
    fi
    CONTEXT=$(kubectl config current-context)
    kubectl create namespace $NAMESPACE
    clusterctl generate cluster $NAME \
        --target-namespace=$NAMESPACE \
        --from https://github.com/mak3r/capi-demo/blob/main/providers/aws/cluster-template.yaml \
        > $NAME-$CONTEXT.yaml
    kubectl apply -f $NAME-$CONTEXT.yaml
    kubectl label cluster.cluster.x-k8s.io $NAME cluster-api.cattle.io/rancher-auto-import=true -n $NAMESPACE
}

create_autoscale_cluster() {
    NAME='default-cluster'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default-cluster' will be used as the cluster name."
    else
        NAME=$1
    fi

    clusterctl generate cluster $NAME \
        --from https://github.com/mak3r/capi-demo/blob/main/providers/aws/cluster-template-autoscale.yaml \
        > $NAME.yaml
    kubectl apply -f $NAME.yaml
}

# Create an autoscaling cluster in a specific namespace
# Name then namespace as arguments
create_autoscale_cluster_in_namespace() {
    NAME='default-cluster'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default-cluster' will be used as the cluster name."
    else
        NAME=$1
    fi

    NAMESPACE='default'
    if [ -z "$1" ]; then
        echo "Warning: No argument provided. 'default' will be used as the cluster namespace."
    else
        NAMESPACE=$2
    fi
    CONTEXT=$(kubectl config current-context)
    kubectl create namespace $NAMESPACE
    clusterctl generate cluster $NAME \
        --target-namespace=$NAMESPACE \
        --from https://github.com/mak3r/capi-demo/blob/main/providers/aws/cluster-template-autoscale.yaml \
        > $NAME-$CONTEXT.yaml
    kubectl apply -f $NAME-$CONTEXT.yaml
    kubectl label cluster.cluster.x-k8s.io $NAME cluster-api.cattle.io/rancher-auto-import=true -n $NAMESPACE
}

import_clusters_in_namespace() {
    NAMESPACE='default'
    if [ -z "$1" ]; then
        echo -e "\033[31mWarning: No argument provided. 'clusters in default namespace will be imported.\033[0m"
    else
        NAMESPACE=$1
    fi

    kubectl label namespace $NAMESPACE cluster-api.cattle.io/rancher-auto-import=true
}

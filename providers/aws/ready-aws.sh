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

    # Airgapped AMI
    # "Name": "amazon-ebs.openSUSE-leap-15.6-rke2"
    # us-east-1: ami-04418d0a73ebfbb4a
    # us-west-1: ami-061e0d437b327464e
    export AWS_AMI_ID="ami-04418d0a73ebfbb4a"


    # Select instance types
    export AWS_CONTROL_PLANE_MACHINE_TYPE=t3a.large
    export AWS_NODE_MACHINE_TYPE=t3a.large
    export RKE2_VERSION=v1.30.3+rke2r1
    export CONTROL_PLANE_MACHINE_COUNT=3
    export WORKER_MACHINE_COUNT=2
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
}


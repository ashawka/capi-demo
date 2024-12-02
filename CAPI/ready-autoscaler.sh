#!/bin/sh

# It would be nice to add some checks to see if the prerequisites are met
# and also if the resources already exist in the management cluster


install_autoscaler() {
    export AUTOSCALER_NS=kube-system
    export AUTOSCALER_IMAGE=registry.k8s.io/autoscaling/cluster-autoscaler:v1.29.0

    envsubst < CAPI/ClusterAutoscaler.yaml | kubectl apply -f -
}

remove_autoscaler() {
    export AUTOSCALER_NS=kube-system
    export AUTOSCALER_IMAGE=registry.k8s.io/autoscaling/cluster-autoscaler:v1.29.0

    kubectl delete -f CAPI/ClusterAutoscaler.yaml
}

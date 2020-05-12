#!/bin/bash
#
# This script is intended to be used for internal testing only, to create the artifacts necessary for 
# testing and deploying this code in a sample GKE cluster.
PROJECT=neo4j-helm
CLUSTER=${1:-helm-test}
ZONE=us-central1-a
MACHINE=n1-highmem-4
NODES=4
API=beta

gcloud beta container clusters create $CLUSTER \
    --zone "$ZONE" \
    --project $PROJECT \
    --machine-type $MACHINE \
    --num-nodes $NODES \
    --enable-ip-alias \
    --no-enable-autoupgrade \
    --max-nodes "10" \
    --enable-autoscaling
    
gcloud container clusters get-credentials $CLUSTER \
   --zone $ZONE \
   --project $PROJECT

# Configure local auth of docker so that we can use regular
# docker commands to push/pull from our GCR setup.
# gcloud auth configure-docker

# Bootstrap RBAC cluster-admin for your user.
# More info: https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin --user $(gcloud config get-value account)

# TO DELETE
# helm del --purge mygraph
# kubectl delete configmaps mygraph-neo4j-ubc

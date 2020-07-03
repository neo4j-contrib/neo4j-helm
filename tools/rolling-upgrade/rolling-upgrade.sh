#!/bin/bash

export DEPLOY=r2
export NEW_VERSION=neo4j:4.1.0-enterprise

# Update Strategies: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies
STRATEGY=RollingUpdate
# STRATEGY=OnDelete

for set in core replica ; do
   kubectl patch statefulset $DEPLOY-neo4j-$set -p '{"spec":{"updateStrategy":{"type":"'$STRATEGY'"}}}'
done

kubectl patch statefulset $DEPLOY-neo4j-core --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"'$NEW_VERSION'"}]'
[]
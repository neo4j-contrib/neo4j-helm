#!/bin/bash

DEPLOY=r2


for idx in 0 1 2 ; do
    kubectl exec -it $DEPLOY-neo4j-core-$idx /bin/cat /var/lib/neo4j/logs/debug.log > $DEPLOY-$idx.log
done

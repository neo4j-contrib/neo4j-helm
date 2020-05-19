#!/bin/bash

release=$1
echo `pwd`
for idx in 0 1 2 ; do
   kubectl exec -it $release-neo4j-core-$idx /bin/cat /data/logs/debug.log > test/$idx/debug.log
done

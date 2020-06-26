# Rolling Upgrades:  Neo4j in Kubernetes

This document expands on the Neo4j Operations Manual entry
[Upgrade a Causal Cluster](https://neo4j.com/docs/operations-manual/current/upgrade/causal-cluster/) with information about approaches on rolling upgrades in Kubernetes.

*It is strongly recommended that you read all of that documentation before using this method*.

Not all relevant concepts will be described in this document.  Familiarity with the page above will be assumed.

*It is recommended to perform a test upgrade on a production-like environment to get information on the duration of the downtime, if any, that may be necessary.*

## When do you need to do a rolling upgrade?

* When you have a Neo4j Causal Cluster (standalone does not apply)
* When you need to upgrade to a new minor or patch version of Neo4j
* When you must maintain the cluster online with both read and write capabilities during the course of the upgrade process.

## High-Level Approach

This tools directory will provide advice and guidance, but not ready-made software because 
careful planning and design for *your* system is necessary before you perform this operation.

* Take a backup
* Scale the core statefulset up, by adding 2 more members (keeping total number of members odd). 
* Choose and apply your UpdateStrategy.
* Patch the statefulset to apply the new Neo4j version
* Monitor the process
* Scale back down on success to the original size.

We will now describe each step, and why it should happen.

## Take a Backup

Before doing any major system maintenance operation, it's crucial to have an up-to-date backup, ensuring that if anything goes wrong, there is a point in time to return to for the database's state.

In addition, all operations should be tested on a staging or a production-like environment as a "dry run" before attempting this on application-critical systems.

## Scale the Core Statefulset Up

If you'd normally have 3 core members in your statefulset, they are providing a valuable 
[high availability purpose, and a quorum](https://neo4j.com/docs/operations-manual/current/clustering/introduction/#causal-clustering-introduction-operational).

In a rolling upgrade operation, we are going to take each server *down* in its turn.  And while one is stopping/restarting, we're (temporarily) damaging the HA characteristics of the
cluster, reducing it's ability to serve queries.   To mitigate this, before doing
a rolling upgrade we scale the cluster *up*, from say 3 cores to 5.  We will then roll
changes through - we will at any given moment have 4 of 5 cores available.

Given a cluster deployment named "mygraph", you can scale it to 5 cores like so:

```
kubectl scale statefulsets mygraph-neo4j-core --replicas=5
```

This should immediately schedule 2 new pods with the same configuration (and the *old* version of Neo4j) to start up and join the cluster.

> **REMEMBER** when new members join the cluster, before the cluster is stable, they
> need to pull current transactional state.  Having members restore from a recent
> backup first is strongly recommended, to minimize the load of the 
> [catch-up process](https://neo4j.com/docs/operations-manual/current/clustering-advanced/lifecycle/#causal-clustering-catchup-protocol).

Consult [scaling statefulsets](https://kubernetes.io/docs/tasks/run-application/scale-stateful-set/#scaling-statefulsets) in the kubernetes documentation for more information.

### Criticality of Readiness / Liveness Checks

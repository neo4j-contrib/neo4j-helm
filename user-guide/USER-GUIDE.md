# Neo4j-Helm User Guide

## Overview

Neo4j-helm allows users to deploy multi-node Neo4j Enterprise Causal Clusters to Kubernetes instances, with configuration options for the most common scenarios.  It represents a very rapid way to get started running the world leading native graph database on top of Kubernetes.

This guide is intended only as a supplement to the [Neo4j Operations Manual](https://neo4j.com/docs/operations-manual/4.0/?ref=googlemarketplace).   Neo4j-helm is essentially a docker container based deploy of Neo4j Causal Cluster.  As such, all of the information in the Operations Manual applies to its operation, and this guide will focus only on kubernetes-specific concerns.

## Architecture

In addition to the information in this user guide, a set of slides is available on the
deployment architecture and chart structure of this repository.

* [Neo4j Helm Chart Structure](https://docs.google.com/presentation/d/14ziuwTzB6O7cp7fq0mA1lxWwZpwnJ9G4pZiwuLxBK70/edit?usp=sharing)

## Prerequisites

* Kubernetes 1.6+ with Beta APIs enabled
* Docker and kubectl installed locally
* Helm >= 3.1 installed
* PV provisioner support in the underlying infrastructure
* Requires the following variables
  You must add `acceptLicenseAgreement` in the values.yaml file and set it to `yes` or include `--set acceptLicenseAgreement=yes` in the command line of helm install to accept the license.
* This chart requires that you have a license for Neo4j Enterprise Edition.  Trial licenses 
[can be obtained here](https://neo4j.com/lp/enterprise-cloud/?utm_content=kubernetes)

## Licensing & Cost

Neo4j Enterprise Edition (EE) is available to any existing enterprise license holder of Neo4j in a Bring Your Own License (BYOL) arrangement.  Neo4j EE is also available under evaluation licenses, contact Neo4j in order to obtain one.   There is no hourly or metered cost associated with using Neo4j EE for current license holders.

## Installation

This is a helm chart, and it is installed by running [helm install](https://helm.sh/docs/helm/helm_install/) with
various parameters used to customize the deploy.

The default for this chart is to install [Neo4j Causal Cluster](https://neo4j.com/docs/operations-manual/current/clustering/)*, with 3 core members and zero replicas, but standalone is also supported.

### Deployment Scenarios

See the [`deployment-scenarios`](../deployment-scenarios) folder in this repo for example YAML values files.
These are example configurations that show settings necessary to launch
the helm chart in different configurations.

Each of these scenario files is launched the same way:

```
$ helm install mygraph -f deployment-scenarios/my-scenario.yaml . 
```

### Causal Cluster Command Line Example

```bash
$ helm install my-neo4j --set core.numberOfServers=3,readReplica.numberOfServers=3,acceptLicenseAgreement=yes,neo4jPassword=mySecretPassword .
```

The above command creates a cluster containing 3 core servers and 3 read
replicas.

Alternatively, a YAML file that specifies the values for the parameters can be
provided while installing the chart. For example,

```bash
$ helm install neo4j-helm -f values.yaml .
```

> **Tip**: You can use the default [values.yaml](../values.yaml)

### Standalone (Single Machine) Command Line Example

```bash
$ helm install my-neo4j --set core.standalone=true,acceptLicenseAgreement=yes,neo4jPassword=mySecretPassword .
```

Important notes about standalone mode:

1. When running in standalone mode, `core.numberOfServers` is *ignored* and you will get 1 server.
2. Read replicas may only be used with causal cluster.  When running standalone, all read replica
arguments are *ignored*.
3. All other core settings (persistent volume size, annotations, etc) will still apply to your single instance.

## Helm Configuration

The following table lists the configurable parameters of the Neo4j chart and
their default values.

| Parameter                             | Description                                                                                                                             | Default                                         |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `image`                               | Neo4j image                                                                                                                             | `neo4j`                                         |
| `imageTag`                            | Neo4j version                                                                                                                           | `{VERSION}`                                     |
| `imagePullPolicy`                     | Image pull policy                                                                                                                       | `IfNotPresent`                                  |
| `podDisruptionBudget`                 | Pod disruption budget                                                                                                                   | `{}`                                            |
| `authEnabled`                         | Is login/password required?                                                                                                             | `true`                                          |
| `useAPOC`                             | Should the APOC plugins be automatically installed in the database?                                                                     | `true`                                          |
| `defaultDatabase`                     | The name of the default database to configure in Neo4j (dbms.default_database)                                                          | `neo4j`                                         |
| `neo4jPassword`                       | Password to log in the Neo4J database if password is required                                                                           | (random string of 10 characters)                |
| `core.configMap`                      | Configmap providing configuration for core cluster members.  If not specified, defaults that come with the chart will be used.          | `$NAME-neo4j-core-config`                       |
| `core.standalone`                     | Whether to run in single-server STANDALONE mode.   When using standalone mode, core.numberOfServers is *ignored* and you will only get 1 Neo4j Pod.  The remainder of core configuration applies. | false |
| `core.numberOfServers`                | Number of machines in CORE mode                                                                                                         | `3`                                             |
| `core.sideCarContainers`              | Sidecar containers to add to the core pod. Example use case is a sidecar which identifies and labels the leader when using the http API | `{}`                                            |
| `core.initContainers`                 | Init containers to add to the core pod. Example use case is a script that installs custom plugins/extensions                            | `{}`                                            |
| `core.persistentVolume.enabled`       | Whether or not persistence is enabled                                                                                                   | `true`                                          |
| `core.persistentVolume.storageClass`  | Storage class of backing PVC                                                                                                            | `standard` (uses beta storage class annotation) |
| `core.persistentVolume.size`          | Size of data volume                                                                                                                     | `10Gi`                                          |
| `core.persistentVolume.mountPath`     | Persistent Volume mount root path                                                                                                       | `/data`                                         |
| `core.persistentVolume.subPath`       | Subdirectory of the volume to mount                                                                                                     | `nil`                                           |
| `core.persistentVolume.annotations`   | Persistent Volume Claim annotations                                                                                                     | `{}`                                            |
| `core.service.type` | Service type | `ClusterIP` |
| `core.service.annotations` | Service annotations | `{}` |
| `core.service.labels` | Custom Service labels | `{}` |
| `core.service.loadBalancerSourceRanges` | List of IP CIDRs allowed access to LB (if `core.service.type: LoadBalancer`) | `[]` |
| `core.discoveryService.type` | Service type | `ClusterIP` |
| `core.discoveryService.annotations` | Service annotations | `{}` |
| `core.discoveryService.labels` | Custom Service labels | `{}` |
| `core.discoveryService.loadBalancerSourceRanges` | List of IP CIDRs allowed access to LB (if `core.discoveryService.type: LoadBalancer`) | `[]` |
| `readReplica.configMap`               | Configmap providing configuration for RR cluster members.  If not specified, defaults that come with the chart will be used.            | `$NAME-neo4j-replica-config`                    |
| `readReplica.numberOfServers`         | Number of machines in READ_REPLICA. May not be used with core.standalone=true mode                                                                                                 | `0`                                             |
| `readReplica.autoscaling.enabled`  | Enable horizontal pod autoscaler  | `false`  |
| `readReplica.autoscaling.targetAverageUtilization`  | Target CPU utilization  | `70`  |
| `readReplica.autoscaling.minReplicas` | Min replicas for autoscaling  | `1`  |
| `readReplica.autoscaling.maxReplicas`  | Max replicas for autoscaling  | `3` |
| `readReplica.initContainers`          | Init containers to add to the replica pods. Example use case is a script that installs custom plugins/extensions                        | `{}`                                            |
| `readReplica.persistentVolume.*`       | See `core.persistentVolume.*` settings; they behave identically for read replicas                                                      | `true`                                          |
| `readReplica.service.type` | Service type | `ClusterIP` |
| `readReplica.service.annotations` | Service annotations | `{}` |
| `readReplica.service.labels` | Custom Service labels | `{}` |
| `readReplica.service.loadBalancerSourceRanges` | List of IP CIDRs allowed accessto LB (if `readReplica.service.type: LoadBalancer`) | `[]` |
| `resources`                           | Resources required (e.g. CPU, memory)                                                                                                   | `{}`                                            |
| `clusterDomain`                       | Cluster domain                                                                                                                          | `cluster.local`                                 |
| `restoreSecret`                       | The name of the kubernetes secret to mount to `/creds` in the container.  Please see the [restore documentation](../tools/restore/README-RESTORE.md) for how to use this. | (none) |

## Backup

See [the documentation on the backup helm chart](../tools/backup/README-BACKUP.md).

## Restore

See [the documentation on the restore process](../tools/restore/README-RESTORE.md).

## Memory Management

The chart follows the same memory configuration settings as described in the [Memory Configuration](https://neo4j.com/docs/operations-manual/current/performance/memory-configuration/) section of the Operations manual.  

### Default Approach

Neo4j-helm behaves just like the regular Neo4j product.  No explicit heap or page cache is set.

### Recommended Approach

You may use the setting `dbms.memory.use_memrec=true` and this will run [neo4j-admin memrec](https://neo4j.com/docs/operations-manual/current/tools/neo4j-admin-memrec/) and use its recommendations.  This use_memrec setting
is an option for the *helm chart*, it is not a Neo4j configuration option.

It's very important that you also specify CPU and memory resources on launch that are adequate to support the
recommendations.  Crashing pods, "unscheduleable" errors, and other problems will result if the recommended amounts 
of memory are higher than the Kubernetes requests/limits.

### Custom Explicit Settings

You may set any of the following settings.  The helm chart accepts these settings, mirroring the names
used in the `neo4j.conf` file.

* `dbms.memory.heap.initial_size`
* `dbms.memory.heap.max_size`
* `dbms.memory.pagecache.size`

Their meanings, formats, and defaults are the same as found in the operations manual.  See the section
"Passing Custom Configuration as a ConfigMap" for how to set these settings for your database.

## Monitoring

This chart supports the same monitoring configuration settings as described in the 
[Neo4j Operations Manual](https://neo4j.com/docs/operations-manual/current/monitoring/metrics/expose/).  These have been ommitted from the
table above because they are documented in the operational manual, but here are three quick examples:

* To publish prometheus metrics, `--set metrics.prometheus.enabled=true,metrics.prometheus.endpoint=localhost:2004`
* To publish graphite metrics, `--set metrics.graphite.enabled=true,metrics.graphite.server=localhost:2003,metrics.graphite.interval=3s`
* To adjust CSV metrics (enabled by default) use `metrics.csv.enabled` and `metrics.csv.interval`.
* To disable JMX metrics (enabled by default) use `metrics.jmx.enabled=false`.

## Data Persistence

The most important data is kept in the `/data` volume attached to each of the core cluster members.  These in turn
are mapped to PersistentVolumeClaims in Kubernetes, and they are *not* deleted when you run `helm uninstall mygraph`.

For further durability of data, regularly scheduled [backups](../tools/backup/README-BACKUP.md) are recommended.

## Fabric

In Neo4j 4.0+, [fabric](https://neo4j.com/docs/operations-manual/current/fabric/introduction/) is a feature that can be enabled with regular configuration in neo4j.conf.  All of the fabric configuration that is referenced in the manual can be done via custom 
ConfigMaps described in this documentation.  

Using Neo4j Fabric in kubernetes boils down to configuring the product as normal, but with the “docker style".  
In the neo4j operations manual, it might tell you to set `fabric.database.name=myfabric` and in kubernetes that would be `NEO4J_fabric_database_name: myfabric` and so forth.

So that is fairly straightforward.  But this is only one half of the story.  The other half is, what is the fabric deployment topology?   

### Fabric Topology

[Fabric enables some very complex setups](https://neo4j.com/docs/operations-manual/current/fabric/introduction/#_multi_cluster_deployment).  If you have a single DBMS* you can do it with pure configuration and it will work.  If you have multiple DBMSs, then the way this works behind the scenes is via account/role coordination, and bolt connections between clusters.   

That in turn means that you would need to have network routing bits set up so that cluster A could talk to cluster B (referring to the diagram linked above).  This would mostly be kubernetes networking stuff, nothing too exotic, but this would need to be carefully planned for.

Where this gets complicated is when the architecture gets big/complex.  Suppose you’re using fabric to store shards of a huge “customer graph”.  The shard of US customers exists in one geo region, and the shard of EU customers in another geo region.  You can use fabric to query both shards and have a logical view of the “customer graph” over all geos.  To do this in kubernetes though would imply kubernetes node pools in two different geos, and almost certainly 2 different neo4j clusters.  To enable bolt between them (permitting fabric to work) would get into a more advanced networking setup for kubernetes specifically.  But to neo4j as a product, it’s all the same.  Can I make a neo4j/bolt connection to the remote source?   Yes?  Then it should be fine.

### How Fabric Works

What fabric needs to work are 3 things:

1. A user/role (neo4j/admin for example) that is the same on all databases subject to the fabric query
2. The ability to make a bolt connection to all cluster members participating in the fabric query
3. Some configuration.

Custom configmaps cover #3.  Your security configuration (whatever you choose) would cover #1 and isn’t kubernetes specific.  And #2 is where kubernetes networking may or may not come in, depending on your deployment topology.  In the simplest single DBMS configurations, I think it will work out of the box.

## Passing Custom Configuration as a ConfigMap

Neo4j cluster pods are divided into two groups: cores and replicas.  Those pods can be configured with ConfigMaps,
which contain environment variables. Those environment variables, in turn, are used as configuration settings to 
the underlying Neo4j Docker Container, according to the [Neo4j environment variable configuration](https://neo4j.com/docs/operations-manual/current/docker/configuration/#docker-environment-variables).

As a result, you can set any custom Neo4j configuration by creating your own Kubernetes configmap, and using it like this:

```
--set core.configMap=myConfigMapName --set readReplica.configMap=myReplicaConfigMap
```

*Note*: configuration of some networking specific settings is still done at container start time,
and this very small set of variables may still be overridden by the helm chart, in particular advertised addresses & hostnames for the containers.

## Hardware & Machine Shape

In order to ensure that Neo4j is deployable on basic/default K8S clusters, the default values for hardware requests have been made fairly low, and can be found in [values.yaml](../values.yaml).

Sizing databases is ultimately something that should be done with the workload in mind.
Consult Neo4j's [Performance Tuning Documentation](https://neo4j.com/developer/guide-performance-tuning/?ref=googlemarketplace) for more information.  In general,
heap size and page cache sizing are the most important places to start when tuning performance.

It is strongly recommended that you choose request and limit values for CPU and memory prior to deploying in
important environments.

## Networking

### Neo4j Browser

**In order to use Neo4j Browser you must follow the external exposure instructions found in this repository**.

Neo4j browser is available on port 7474 of any of the hostnames described above.  However, because of the network environment that the cluster is in, hosts in the neo4j cluster advertise themselves with private internal DNS that is not resolvable from outside of the cluster.

The [external exposure instructions](../tools/external-exposure/EXTERNAL-EXPOSURE.md) provide a walk-through of
how you can configure this for your environment.

### Exposed Services

By default, each node will expose:
- HTTP on port 7474
- HTTPS on port 7473
- Bolt on port 7687

Exposed services and port mappings can be configured by referencing neo4j’s docker documentation.   See the advanced configuration section in this document for how to change the way the docker containers in each pod are configured.

### Service Address

Additionally, a service address inside of the cluster will be available as follows - to determine your service address, simply substitute $APP_INSTANCE_NAME with the name you deployed neo4j under, and $NAMESPACE with the kubernetes namespace where neo4j resides.

`$NAME-neo4j.$NAMESPACE.svc.cluster.local`

Any client may connect to this address, as it is a DNS record with multiple entries pointing to the nodes which back the cluster.  For example, bolt+routing clients can use this address to bootstrap their connection into the cluster, subject to the items in the limitations section.

### Cluster Formation

Immediately after deploying Neo4j, as the pods are created the cluster begins to form.  This may take up to 5 minutes, depending on a number of factors including how long it takes pods to get scheduled, and how many resources are associated with the pods.  While the cluster is forming, the Neo4j REST API and Bolt endpoints may not be available.   After a few minutes, bolt endpoints become available inside of the kubernetes cluster.  

## Password

After installing, your cluster will start with the password you supplied as the neo4jPassword setting. This is stored in a kubernetes secret that is attached to your deployment.   Given a deployment named “my-graph”, you can find the password as the “neo4j-password” key under the mygraph-neo4j-secrets configuration item in Kubernetes.   The password is base64 encoded, and can be recovered as plaintext by authorized users with this command:

```
export NEO4J_PASSWORD=$(kubectl get secrets {{ template "neo4j.secrets.fullname" . }} -o yaml | grep password | sed 's/.*: //' | base64 -d)
```

This password applies for the base administrative user named “neo4j”.

## Usage

### Cypher Shell

Upon deploying the helm chart, you will be given a command that can be used to connect to the cluster.  This
will schedule a new Neo4j pod to run called "cypher-shell" and invoke that command to connect.   See NOTES.txt
for an example.

Please consult standard Neo4j documentation on the many other usage options present, once you have a basic bolt client and cypher shell capability.

## Scaling

The following section describes considerations about changing the size of a cluster at runtime to handle more 
requests.  Scaling only applies to causal cluster, and standalone instances cannot be scaled in this way.

### Planning

Before scaling a database running on kubernetes, make sure to consult in depth the Neo4j documentation on clustering architecture, and in particular take care to choose carefully between whether you want to add core nodes or read replicas.  Additionally, this planning process should take care to include details of the kubernetes layer, and where the node pools reside.  Adding extra core nodes to protect data with additional redundancy may not provide extra guarantees if all kubernetes nodes are in the same zone, for example.

For many users and use cases, careful planning on initial database sizing is preferable to later attempts to rapidly scale the cluster.

When adding new nodes to a neo4j cluster, upon the node joining the cluster, it will need to replicate the existing data from the other nodes in the cluster.  As a result, this can create a temporary higher load on the remaining nodes as they replicate data to the new member.   In the case of very large databases, this can cause temporary unavailability under heavy loads.  We recommend
that when setting up a scalable instance of Neo4j, you configure pods to restore from a recent
backup set before starting.  Instructions on how to restore are provided in this repo.  In this way,
new pods are mostly caught up before entering the cluster, and the "catch-up" process is minimal both
in terms of time spent and load placed on the rest of the cluster.

Because of the data intensive nature of any database, careful planning before scaling is highly recommended.   Storage allocation for each new node is also needed; as a result, when scaling the database, the kubernetes cluster will create new persistent volume claims and GCE volumes.

Because Neo4j's configuration is different in single-node mode (dbms.mode=SINGLE) you should not
scale a deployment if it was initially set to 1 coreServer.  This will result in multiple independent
databases, not one cluster.

### Execution

Neo4j-Helm consists of a StatefulSet for core nodes, and a Deployment for replicas.  In configuration, even if you chose zero replicas, you will see a Deployment with zero members.

Scaling the database is a matter of scaling one of these elements. 

Depending on the size of your database and how busy the other members are, it may take considerable time for the cluster topology to show the presence of the new member, as it connects to the cluster and performs catch-up.
Once the new node is caught up, you can execute the cypher query CALL dbms.cluster.overview(); to verify that the new node is operational.

### Warnings and Indications

Scaled pods inherit their configuration from their statefulset.  For neo4j, this means that items like configured storage size, hardware limits, and passwords apply to scale up members.

If scaling down, do not scale below three core nodes; this is the minimum necessary to guarantee a properly functioning cluster with data redundancy.   Consult the neo4j clustering documentation for more information.
Neo4j-Helm uses PVCs, and so if you scale up and then later scale down, this may orphan an underlying PVC, which 
you may want to manually delete at a later date.

## Security

For security reasons, we have not enabled access to the database cluster from outside of Kubernetes by default, instead choosing to leave this to users to configure appropriate network access policies for their usage.  If this is desired, please look at the [external exposure](../tools/external-exposure/EXTERNAL-EXPOSURE.md) instructions found in this repository.

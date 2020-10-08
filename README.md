[![CircleCI](https://circleci.com/gh/neo4j-contrib/neo4j-helm.svg?style=svg)](https://circleci.com/gh/neo4j-contrib/neo4j-helm)

# Neo4j-Helm

This repository contains a Helm chart that starts Neo4j >= 4.0 Enterprise Edition clusters in Kubernetes.

[Full Documentation can be found here](https://neo4j.com/labs/neo4j-helm/1.0.0/)

## Quick Start

Check the [releases page](https://github.com/neo4j-contrib/neo4j-helm/releases) and copy the URL of the tgz package.   Make sure to note the correct version of Neo4j.

### Standalone (single server)

```bash
$ helm install mygraph RELEASE_URL --set core.standalone=true --set acceptLicenseAgreement=yes --set neo4jPassword=mySecretPassword
```

### Casual Cluster (3 core, 0 read replicas)

```bash
$ helm install mygraph RELEASE_URL --set acceptLicenseAgreement=yes --set neo4jPassword=mySecretPassword
```

When you're done:  `helm uninstall mygraph`.

## Documentation

The [User Guide](https://neo4j.com/labs/neo4j-helm/1.0.0/) contains all the documentation for this helm chart.

The [Neo4j Community Site](https://community.neo4j.com/c/neo4j-graph-platform/cloud/76) is a great place to go for
discussion and questions about Neo4j & Kubernetes.

Additional instructions, general documentation, and operational facets are covered in the following
articles:

- [Architectural Documentation describing how the helm chart is put together](https://docs.google.com/presentation/d/14ziuwTzB6O7cp7fq0mA1lxWwZpwnJ9G4pZiwuLxBK70/edit?usp=sharing)
- [External exposure of Neo4j clusters on Kubernetes](tools/external-exposure/EXTERNAL-EXPOSURE.md) - how to use
tools like Neo4j Browser and cypher-shell from clients originating outside of Kubernetes
- [Neo4j Considerations in Orchestration Environments](https://medium.com/neo4j/neo4j-considerations-in-orchestration-environments-584db747dca5) which covers
how the smart-client routing protocol that Neo4j uses interacts with Kubernetes networking.  Make sure to read this if you are trying to expose the Neo4j database outside
of Kubernetes
- [How to Backup Neo4j Running in Kubernetes](https://medium.com/neo4j/how-to-backup-neo4j-running-in-kubernetes-3697761f229a)
- [How to Restore Neo4j Backups on Kubernetes](https://medium.com/google-cloud/how-to-restore-neo4j-backups-on-kubernetes-and-gke-6841aa1e3961)

## Helm Testing

This chart contains a standard set of [helm chart tests](https://helm.sh/docs/topics/chart_tests/), which 
can be run after a deploy is ready, like this:

```
helm test mygraph
```

## Local Testing & Development

### Template Expansion

To see what helm will actually deploy based on the templates:

```
helm template --name-template tester --set acceptLicenseAgreement=yes --set neo4jPassword=mySecretPassword . > expanded.yaml
```

### Full-Cycle Test

The following mini-script will provision a test cluster, monitor it for rollout, test it,
report test results, and teardown / destroy PVCs.

#### Provision K8S Cluster

Please use the `tools/test/provision-k8s.sh`, and customize your Google Cloud
project ID.

#### Standalone

Standalone forms faster so we can manually lower the liveness/readiness timeouts.

```
export NAME=a
export NAMESPACE=default
helm install $NAME . -f deployment-scenarios/ci/standalone.yaml && \
kubectl rollout status --namespace $NAMESPACE StatefulSet/$NAME-neo4j-core --watch && \
helm test $NAME --logs | tee testlog.txt
helm uninstall $NAME
sleep 20
for idx in 0 1 2 ; do
  kubectl delete pvc datadir-$NAME-neo4j-core-$idx ;
done
```

#### Causal Cluster

```
export NAME=a
export NAMESPACE=default
helm install $NAME . -f deployment-scenarios/ci/cluster.yaml && \
kubectl rollout status --namespace $NAMESPACE StatefulSet/$NAME-neo4j-core --watch && \
helm test $NAME --logs | tee testlog.txt
helm uninstall $NAME
sleep 20
for idx in 0 1 2 ; do
  kubectl delete pvc datadir-$NAME-neo4j-core-$idx ;
done
```

## Internal Tooling

This repo contains internal tooling containers for backup, restore, and test of
the helm chart.

### Building the Containers

If you want to push your own docker containers, make sure that the registry in 
the Makefile is set to somewhere you have permissions on.

```
cd tools
make docker_build
make docker_push
```

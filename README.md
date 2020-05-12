# Neo4j

[![CircleCI](https://circleci.com/gh/neo4j-contrib/neo4j-helm.svg?style=svg)](https://circleci.com/gh/neo4j-contrib/neo4j-helm)

[Neo4j](https://neo4j.com/) is a highly scalable native graph database that
leverages data relationships as first-class entities, helping enterprises build
intelligent applications to meet today’s evolving data challenges.

This chart bootstraps a [Neo4j](https://github.com/neo4j/docker-neo4j)
deployment on a [Kubernetes](http://kubernetes.io) cluster using the
[Helm](https://helm.sh) package manager.

This package is fairly similar to the Neo4j-maintained [GKE Marketplace](https://github.com/neo-technology/neo4j-google-k8s-marketplace) 
entry, which is also built on helm.  This package tries to avoid Kubernetes distribution-specific features to be general, while the other
is tailored specifically to GKE.

## Prerequisites

* Kubernetes 1.6+ with Beta APIs enabled
* Docker and kubectl installed locally
* Helm >= 3.1 installed
* PV provisioner support in the underlying infrastructure
* Requires the following variables
  You must add `acceptLicenseAgreement` in the values.yaml file and set it to `yes` or include `--set acceptLicenseAgreement=yes` in the command line of helm install to accept the license.
* This chart requires that you have a license for Neo4j Enterprise Edition.  Trial licenses 
[can be obtained here](https://neo4j.com/lp/enterprise-cloud/?utm_content=kubernetes)

## Quick Start

To install the chart with the release name `neo4j-helm`:

```bash
$ helm install neo4j-helm . --set acceptLicenseAgreement=yes --set neo4jPassword=mySecretPassword
```

You must explicitly accept the neo4j license agreement for the installation to be successful.

## Uninstalling the Chart

To uninstall/delete the `neo4j-helm` deployment:

```bash
$ helm uninstall neo4j-helm
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.  Be aware that it may orphan PVCs associated with the StatefulSet.

## User Guide

For a complete list of configuration options, and ways of installing, please see
[the user guide](user-guide/USER-GUIDE.md)

## Additional Documentation for Running Neo4j in Kubernetes

- [Neo4j Considerations in Orchestration Environments](https://medium.com/neo4j/neo4j-considerations-in-orchestration-environments-584db747dca5) which covers
how the smart-client routing protocol that Neo4j uses interacts with Kubernetes networking.  Make sure to read this if you are trying to expose the Neo4j database outside
of Kubernetes
- [How to Backup Neo4j Running in Kubernetes](https://medium.com/neo4j/how-to-backup-neo4j-running-in-kubernetes-3697761f229a)
- [How to Restore Neo4j Backups on Kubernetes](https://medium.com/google-cloud/how-to-restore-neo4j-backups-on-kubernetes-and-gke-6841aa1e3961)

## Versioning

Version numbers here refer to helm chart versions, not Neo4j product versions.

This repo contains version 3.0.0 of the helm chart, which supports Neo4j 4.0 going forward.  This helm chart is *not* backwards
compatible with helm charts built for versions in the Neo4j 3.5 series.

The 2.0.0 chart was based around Neo4j's 3.5.x product series.  The 3.0 chart is based around Neo4j's 4.0.x product
series, and there are *substantial differences* between these two.  Careful upgrade planning is advised before attempting
to upgrade an existing chart.  Consult [the upgrade guide](https://neo4j.com/docs/operations-manual/current/upgrade/) and
expect that additional configuration of this chart will be necessary.

## Local Expansion

```
helm template --name tester --set acceptLicenseAgreement=yes --set neo4jPassword=mySecretPassword . > expanded.yaml
```

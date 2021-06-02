# Release Process

## Bump all the version numbers

Find-and-replace current version string "X.Y.Z" with new version string "X.Y.Z"

Create a commit with that change and put it in a branch but do not create a PR yet (currently CI will fail)

## Docker Images

Before CI can run for the new beanch it's necessary to build and push docker images from that branch.

**Ensure that you have bumped the version number before pushing docker images**

If you have not bumped the version number then you may overwrite existing docker images for the *old* version - which would cause all kinds of problems.

```
cd tools
make docker_build
```

** double check that the built images are tagged with the correct version **

If you are sure now you can push

```
make docker_push
```

## Circle CI

Neo4j-helm is built & tested on CircleCI.  You can see a dashboard of builds [here](https://app.circleci.com/pipelines/github/neo4j-contrib/neo4j-helm) for the master
branch.  All releases are done from the master branch.

In general, features & bugfixes are developed on sub-branches, and then opened as PRs to the master branch.  [Example feature](https://github.com/neo4j-contrib/neo4j-helm/pull/156)

A release then consists of a number of PRs merged in a time period since the previous release.

## Artifacts

CircleCI builds the final artifacts for the release; [this build](https://app.circleci.com/pipelines/github/neo4j-contrib/neo4j-helm/353/workflows/21f6b50b-22a9-42cd-85cb-856c90c95253/jobs/365) is an example of a recent release. Check the "Artifacts" tab and you will find the following files:

* `build/neo4j-4.2.2-1.tgz`
* `build/neo4j-backup-4.2.2-1.tgz`

The [CircleCI build config](https://github.com/neo4j-contrib/neo4j-helm/blob/master/.circleci/config.yml) controls how this build progresses.  The "Package" steps in the build are what is producing the ending tgz files.

## Draft GitHub Release

Given the log of PRs merged since the last release, [a GitHub release is drafted](https://github.com/neo4j-contrib/neo4j-helm/releases), with the artifacts from CircleCI attached to the release at all times.

This guarantees a reasonably stable & permanent URL for the artifacts, which is necessary in the next step.

In general, release notes are broken into enhancements, bugfixes, and other; simply linking the PRs in question as a record with 1 line of text description.

## Update the Helm Repository

Generally a manual change is pushed to the `index.yaml` file.  The entire github repo functions as a "helm repository" or a provider of helm charts, similar to how a website may be a debian repository.  The `index.yaml` file controls all of that.  The changes to this repo file are basically
- title, version, and description
- a release date `gdate "+%Y-%m-%dT%H:%M:%S.%9N%:z"`
- a sha hash of the file `sha256sum neoj-<version>.tgz neoj-backup-<version>.tgz`

This file gets pushed to master. This file is fairly important though, because it gets reprocessed by other hosting sites such as [Artifact Hub](https://artifacthub.io/packages/helm/neo4j-helm/neo4j) which are used by the community.

There is another repo [cr](https://github.com/helm/chart-releaser) that contains automation tools for working with the helm chart release process, but there hasn't been time to make use of it yet.

## Monitoring Downloads

You can view the number of times that a release has been downloaded at https://tooomm.github.io/github-release-stats/?username=neo4j-contrib&repository=neo4j-helm


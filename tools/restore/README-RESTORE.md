# Restoring Neo4j Containers

This directory contains files necessary for restoring Neo4j Docker containers
from google storage, or local files placed on the volume.

**This approach assumes you have Google Cloud credentials and wish to store your backups
on Google Cloud Storage**.  If this is not the case, you will need to adjust the restore
script for your desired cloud storage method, but the approach will work for any backup location.

**This approach works only for Neo4j 4.0+**.   The tools and the
DBMS itself changed quite a lot between 3.5 and 4.0, and the approach
here will likely not work for older databases without substantial 
modification.

## Approach

The restore container is used as an `initContainer` in the main cluster.  Prior to
a node in the Neo4j cluster starting, the restore container copies down the backup
set, and restores it into place.  When the initContainer terminates, the regular
Neo4j docker instance starts, and picks up where the backup left off.

This container is primarily tested against the backup .tar.gz archives produced by
the `backup` container in this same code repository.  We recommend you use that approach.  If you tar/gz your own backups using a different approach, be careful to
inspect the `restore.sh` script, because it needs to make certain assumptions about
directory structure that come out of archived backups in order to restore properly.


### Create a service key secret to access cloud storage

First you want to create a kubernetes secret that contains the content of your account service key.  This key must have permissions to access the bucket and backup set that you're trying to restore. 

```
MY_SERVICE_ACCOUNT_KEY=$HOME/.google/my-service-key.json
kubectl create secret generic neo4j-service-key \
   --from-file=credentials.json=$MY_SERVICE_ACCOUNT_KEY
```

The restore container is going to take this kubernetes secret
(named `neo4j-service-key`) and is going to mount it as a file
inside of the backup container (`/auth/credentials.json`).  That
file will then be used to authenticate the storage client that we
need to upload the backupset to cloud storage when it's complete.

In `values.yaml`, then configure the secret you set here like so:

```
restoreSecret=neo4j-service-key
```

This allows the core and read replica nodes to access that service key
as a volume.  That volume being present within the containers is necessary for the
next step, and will be mounted as `/auth/credentials.json` inside the container.

If this service key secret is not in place, the auth information will not be able to be mounted as
a volume in the initContainer, and your pods may get stuck/hung at "ContainerCreating" phase.

### Configure the initContainer for Core and Read Replica Nodes

Refer to [this example deployment scenario](../deployment-scenarios/single-instance-restore.yaml) to see how the initContainers are configured.

What you will need to customize and ensure:
* Ensure you have created the appropriate secret and set its name
* Ensure that the volume mount to /auth matches the secret name you created above.
* Ensure that your BUCKET, and GOOGLE_APPLICATION_CREDENTIALS are
set correctly given the way you created your secret.

The example scenario above creates the initContainer just for core nodes.  It's strongly recommended you do the same for `readReplica.initContainers` if you are using read replicas. If you restore only to core nodes and not to read replicas, when they start the core nodes will replicate the data to the read replicas.   This will work just fine, but may result in longer startup times and much more bandwidth.

## Restore Parameters

### Required

- `GOOGLE_APPLICATION_CREDENTIALS` - path to a file with a JSON service account key (see credentials below).   Defaults to /auth/credentials.json
- `BUCKET` - the storage bucket where backups are located, e.g. `gs://bucketname`.   This parameter may include a relative path (`gs://bucketname/mycluster`)
- `DATABASE` - comma-separated list of databases to restore, e.g. neo4j,system
* `TIMESTAMP` - this defaults to "latest".  See the backup container's documentation
on the latest pointer.  But you may set this to a particular timestamp to restore
that exact moment in time.   This timestamp must match the filename in storage.
So if you want to restore the backup set at `neo4j-2020-06-16-12:32:57.tar.gz	` then
the TIMESTAMP would be `2020-06-16-12:32:57`.

### Optional
- `PURGE_ON_COMPLETE` (defaults to true).  If this is set to the value "true", the restore process will remove the restore artifacts from disk.  With any other 
value, they will be left in place.  This is useful for debugging restores, to 
see what was copied down from cloud storage and how it was expanded.
- `FORCE_OVERWRITE` if this is the value "true", then the restore process will overwrite and
destroy any existing data that is on the volume.  Take care when using this in combination with
persistent volumes.  The default is false; if data already exists on the drive, the restore operation will fail but preserve your data.  **You must set this to true
if you want restore to work over-top of an existing database**.

**Warnings**

A common way you might deploy Neo4j would be restore from last backup when a container initializes.  This would be good for a cluster, because it would minimize how much catch-up
is needed when a node is launched.  Any difference between the last backup and the rest of the
cluster would be provided via catch-up.

For single nodes, take extreme care here.  If a node crashes, and you automatically restore from
backup, and force-overwrite what was previously on the disk, you will lose any data that the
database captured between when the last backup was taken, and when the crash happened.  As a
result, for single node instances of Neo4j you should either perform restores manually when you
need them, or you should keep a very regular backup schedule to minimize this data loss.  If data
loss is under no circumstances acceptable, do not automate restores for single node deploys.

## Running the Restore

With the initContainer in place and properly configured, simply deploy a new cluster 
using the regular approach.  Prior to start, the restore will happen, and when the 
cluster comes live, it will be populated with the data.

## Limitations

- If you want usernames, passwords, and permissions to be restored, you must include
a restore of the system graph.
- Container has not yet been tested with incremental backups
- For the time being, only google storage as a cloud storage option is implemented, 
but adapting this approach to S3 or other storage should be fairly straightforward with modifications to `restore.sh`

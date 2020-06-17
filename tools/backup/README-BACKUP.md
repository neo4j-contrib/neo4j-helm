# Backing up Neo4j Containers

This directory contains files necessary for backing up Neo4j Docker containers
to google storage.

**This approach assumes you have Google Cloud credentials and wish to store your backups
on Google Cloud Storage**.  If this is not the case, you will need to adjust the backup
script for your desired cloud storage method, but the approach will work for any backup location.

**This approach works only for Neo4j 4.0+**.   The backup tool and the
DBMS itself changed quite a lot between 3.5 and 4.0, and the approach
here will likely not work for older databases without substantial 
modification.

## Background & Important Information

### Required Neo4j Config

This is provided for you out of the box by the helm chart, but if you
customize you should bear these requirements in mind:

* `dbms.backup.enabled=true`
* `dbms.backup.listen_address=0.0.0.0:6362`

The default for Neo4j is to listen only on 127.0.0.1, which will not
work as other containers would not be able to access the backup port.

### Backup Pointers

All backups will turn into .tar.gz files with date strings when they were taken, such as: `neo4j-2020-06-16-12:32:57.tar.gz`.  They are named after the database
they are a backup of. 

When you take a backup, you will get both the dated version, and a "latest" copy,
e.g. the above file will also be copied to neo4j-latest.tar.gz in the same bucket.

**Reminder: Each time you take a backup, the latest file will be overwritten**.

The purpose of doing this is to have a stable name in storage where the latest
backup can always be found, without losing any of the previous backups.

### Neo4j Backs Up Databases, Not the DBMS

In Neo4j 4.0, the system can be multidatabase; most systems have at least 2 DBs,
"system" and "neo4j".  *These need to be backed up and restored individually*.

## Steps to Take a Backup

### Create a service key secret to access cloud storage

First you want to create a kubernetes secret that contains the content of your account service key.  This key must have permissions to access the bucket and backup set that you're trying to restore. 

```
MY_SERVICE_ACCOUNT_KEY=$HOME/.google/my-service-key.json
kubectl create secret generic neo4j-service-key \
   --from-file=credentials.json=$MY_SERVICE_ACCOUNT_KEY
```

The backup container is going to take this kubernetes secret
(named `neo4j-service-key`) and is going to mount it as a file
inside of the backup container (`/auth/credentials.json`).  That
file will then be used to authenticate the storage client that we
need to upload the backupset to cloud storage when it's complete.

### Running a Backup

See backup.yaml for an example.   You must have first created a `neo4j-service-key`
secret in the same namespace as your Neo4j is running.

**Required environment variables**

* `NEO4J_ADDR` pointing to an address where your cluster is running, ideally the
discovery address.
* `BUCKET` where you want the backup copied to.  It should be `gs://bucketname`
* `DATABASES` a comma separated list of databases to back up.  The default is
`neo4j,system`.  If your DBMS has many individual databases, you should change this.

**Optional environment variables**

All of the following variables mimic the command line options
for [neo4j-admin backup documented here](https://neo4j.com/docs/operations-manual/current/backup/performing/#backup-performing-command)

* `PAGE_CACHE`
* `HEAP_SIZE`
* `FALLBACK_TO_FULL` (true/false), default=true
* `CHECK_CONSISTENCY` (true/false), default=true
* `CHECK_INDEXES` (true/false) default=true
* `CHECK_GRAPH` (true/false), default=true
* `CHECK_LABEL_SCAN_STORE` (true/false), default=true
* `CHECK_PROPERTY_OWNERS` (true/false), default=false

### Launch the Job

```
kubectl apply -f backup.yaml --namespace my-neo4j-namespace
```

If all goes well, after a period of time when the Kubernetes Job is complete, you
will simply see the backup files appear in the designated bucket.
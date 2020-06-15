#!/bin/bash

if [ -z $NEO4J_ADDR ] ; then
    echo "You must specify a NEO4J_ADDR env var"
    exit 1
fi

if [ -z $DATABASE ] ; then
    echo "You must specify a DATABASE env var"
    exit 1
fi

if [ -z $BUCKET ]; then
    echo "You must specify a BUCKET address such as gs://my-backups/"
    exit 1
fi

if [ -z $HEAP_SIZE ] ; then
    export HEAP_SIZE=2G
fi

if [ -z $PAGE_CACHE ]; then
    export PAGE_CACHE=4G
fi

if [ -z $BACKUP_NAME ]; then
    export BACKUP_NAME=neo4j-backup
fi

BACKUP_SET="$BACKUP_NAME-$(date "+%Y-%m-%d-%H:%M:%S")"

echo "Activating google credentials before beginning"
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; no way to copy to google."
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

echo "=============== Neo4j Backup ==============================="
echo "Beginning backup from $NEO4J_ADDR to /data/$BACKUP_SET"
echo "Using heap size $HEAP_SIZE and page cache $PAGE_CACHE"
echo "To google storage bucket $BUCKET using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
echo "============================================================"

neo4j-admin backup \
    --from="$NEO4J_ADDR" \
    --backup-dir=/data \
    --database=$DATABASE \
    --name="$BACKUP_SET" \
    --pagecache=$PAGE_CACHE

echo "Backup size:"
du -hs "/data/$BACKUP_SET"

echo "Tarring -> /data/$BACKUP_SET.tar"
tar -cvf "/data/$BACKUP_SET.tar" "/data/$BACKUP_SET" --remove-files

echo "Zipping -> /data/$BACKUP_SET.tar.gz"
gzip -9 "/data/$BACKUP_SET.tar"

echo "Zipped backup size:"
du -hs "/data/$BACKUP_SET.tar.gz"

echo "Pushing /data/$BACKUP_SET.tar.gz -> $BUCKET"
gsutil cp "/data/$BACKUP_SET.tar.gz" "$BUCKET"

exit $?

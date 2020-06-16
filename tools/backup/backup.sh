#!/bin/bash

if [ -z $NEO4J_ADDR ] ; then
    echo "You must specify a NEO4J_ADDR env var with port, such as my-neo4j:6362"
    exit 1
fi

if [ -z $DATABASE ] ; then
    echo "You must specify a DATABASE env var; comma-separated list of databases to backup, such as neo4j,system"
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

if [ -z $GOOGLE_APPLICATION_CREDENTIALS ] ; then
    echo "Setting default google credential location to /auth/credentials.json"
    export GOOGLE_APPLICATION_CREDENTIALS=/auth/credentials.json
fi

function backup_database {   
    db=$1

    BACKUP_SET="$db-$(date "+%Y-%m-%d-%H:%M:%S")"
    LATEST_POINTER="$db-latest.tar.gz"

    echo "=============== BACKUP $db ==================="
    echo "Beginning backup from $NEO4J_ADDR to /data/$BACKUP_SET"
    echo "Using heap size $HEAP_SIZE and page cache $PAGE_CACHE"
    echo "To google storage bucket $BUCKET using credentials located at $GOOGLE_APPLICATION_CREDENTIALS"
    echo "============================================================"

    neo4j-admin backup \
        --from="$NEO4J_ADDR" \
        --backup-dir=/data \
        --database=$db \
        --pagecache=$PAGE_CACHE \
        --verbose

    if [ $? -ne 0 ] ; then
        echo "BACKUP $db FAILED"
        exit 1
    fi

    echo "Backup size:"
    du -hs "/data/$db"

    echo "Archiving and Compressing -> /data/$BACKUP_SET.tar"
    tar -zcvf "/data/$BACKUP_SET.tar.gz" "/data/$db" --remove-files

    if [ $? -ne 0 ] ; then
       echo "BACKUP ARCHIVING OF $db FAILED"
       exit 1
    fi

    echo "Zipped backup size:"
    du -hs "/data/$BACKUP_SET.tar.gz"

    echo "Pushing /data/$BACKUP_SET.tar.gz -> $BUCKET"
    gsutil cp "/data/$BACKUP_SET.tar.gz" "$BUCKET"

    backup="$BUCKET/$BACKUP_SET.tar.gz"
    latest="$BUCKET/$LATEST_POINTER"

    echo "Updating latest backup pointer $backup -> $latest"
    gsutil cp "$backup" "$latest"

    if [ $? -ne 0 ] ; then
       echo "Storage copy of backup for $db FAILED"
       exit 1
    fi
}

######################################################

echo "Activating google credentials before beginning"
gcloud auth activate-service-account --key-file "$GOOGLE_APPLICATION_CREDENTIALS"

if [ $? -ne 0 ] ; then
    echo "Credentials failed; no way to copy to google."
    echo "Ensure GOOGLE_APPLICATION_CREDENTIALS is appropriately set."
fi

# Split by comma
IFS=","
read -a databases <<< "$DATABASE"
for db in "${databases[@]}"; do  
   backup_database "$db"
done

echo "All finished"
exit 0

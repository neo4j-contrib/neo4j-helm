#!/bin/bash

# Validation of inputs upfront
if [ -z $BUCKET ] ; then
   echo "You must specify a bucket, such as (gs|s3)://my-backups"
   exit 1
fi

if [ -z $DATABASE ]; then
    echo "You must specify a DATABASE list such as neo4j,system"
    exit 1
fi

if [ -z $CLOUD_PROVIDER ]; then
  echo "You must specify a CLOUD_PROVIDER env var"
  exit 1
fi

if [ -z $TIMESTAMP ]; then
    echo "No TIMESTAMP was provided, we are using latest"
    TIMESTAMP=latest
fi

if [ -z $PURGE_ON_COMPLETE ]; then
    echo "Setting PURGE_ON_COMPLETE=true"
    PURGE_ON_COMPLETE=true
fi

function fetch_backup_from_cloud() {
  database=$1
  restore_path=$2

  bucket_path=""
  if [ "${BUCKET: -1}" = "/" ]; then
      bucket_path="${BUCKET%?}/$database/"
  else
      bucket_path="$BUCKET/$database/"
  fi
  backup_path="${bucket_path}$database-$TIMESTAMP.tar.gz"

  echo "Fetching $backup_path -> $restore_path"

  case $CLOUD_PROVIDER in
  aws)
    aws s3 cp $backup_path $restore_path
    ;;
  gcp)
    gsutil cp $backup_path $restore_path
    ;;
  azure)
    # For this tool, you specify BUCKET but this has to be parsed into 
    # CONTAINER/path/file
    IFS='/' read -r -a pathParts <<< "$BUCKET"
    CONTAINER=${pathParts[0]}
    CONTAINER_PATH=${BUCKET#$CONTAINER}
    # Remove all leading and doubled slashes to avoid reading empty folders in azure
    backup_path=$CONTAINER_PATH/$database/$database-$TIMESTAMP.tar.gz    
    backup_path=$(echo "$backup_path" | sed 's|^/*||')
    backup_path=$(echo "$backup_path" | sed s'|//|/|g')

    copy_to_local="$restore_path/$(basename "$backup_path")"
    echo "Azure storage blob copy $backup_path :: $copy_to_local"
    az storage blob download --container-name "$CONTAINER" \
                             --name "$backup_path" \
                             --file "$copy_to_local" \
                             --account-name "$ACCOUNT_NAME" \
                             --account-key "$ACCOUNT_KEY"
    ;;
  esac
}

function print_volumes_state {
    # This data is output because of the way neo4j-admin works.  It writes the restored set to
    # /var/lib/neo4j by default.  This can fail if volumes aren't sized appropriately, so this
    # aids in debugging.
    echo "Volume mounts and sizing"
    df -h
}

function restore_database {
    db=$1

    echo ""
    echo "=== RESTORE $db"

    if [ -d "/data/databases/$db" ] ; then
        echo "You have an existing graph database at /data/databases/$db"

        if [ "$FORCE_OVERWRITE" != "true" ] ; then
            echo "And you have not specified FORCE_OVERWRITE=true, so we will not restore because"
            echo "that would overwrite your existing data.   Exiting.".
            return
        fi
    else 
        echo "No existing graph database found at /data/databases/$db"
    fi

    # Pass the force flag to the restore operation, which will overwrite
    # whatever is there, if and only if FORCE_OVERWRITE=true.
    if [ "$FORCE_OVERWRITE" = true ] ; then
         # Danger: we are destroying previous data on disk.  On purpose.
         # Optional: you can move the database out of the way to preserve the data just in case,
         # but we don't do it this way because for large DBs this will just rapidly fill the disk
         # and cause out of disk errors.
        echo "We will be force-overwriting any data present"
        FORCE_FLAG="--force"
    else
        # Pass no flag in any other setup.
        echo "We will not force-overwrite data if present"
        FORCE_FLAG=""
    fi

    RESTORE_ROOT=/data/.restore

    echo "Making restore directory"
    mkdir -p "$RESTORE_ROOT"

    fetch_backup_from_cloud $db $RESTORE_ROOT

    if [ $? -ne 0 ] ; then
        echo "Cannot restore $db"
        return
    fi

    echo "Backup size pre-uncompress:"
    du -hs "$RESTORE_ROOT"
    ls -l "$RESTORE_ROOT"

    # Important note!  If you have a backup name that is "foo.tar.gz" or 
    # foo.zip, we need to assume that this unarchives to a directory called
    # foo, as neo4j backup sets are directories.  So we'll remove the suffix
    # after unarchiving and use that as the actual backup target.
    BACKUP_FILENAME="$db-$TIMESTAMP.tar.gz"
    RESTORE_FROM=uninitialized
    if [[ $BACKUP_FILENAME =~ \.tar\.gz$ ]] ; then
        echo "Untarring backup file"
        cd "$RESTORE_ROOT" && tar --force-local --overwrite -zxvf "$BACKUP_FILENAME"

        if [ $? -ne 0 ] ; then
            echo "Failed to unarchive target backup set"
            echo "FAILED TO RESTORE $db"
            return
        fi

        # foo-$TIMESTAMP.tar.gz untars/zips to a directory called foo.
        UNTARRED_BACKUP_DIR=$db

        if [ -z $BACKUP_SET_DIR ] ; then
            echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
            if [ -d "$RESTORE_ROOT/backups" ] ; then
                RESTORE_FROM="$RESTORE_ROOT/backups/$UNTARRED_BACKUP_DIR"
            else
                RESTORE_FROM="$RESTORE_ROOT/data/$UNTARRED_BACKUP_DIR"
            fi
        else 
            RESTORE_FROM="$RESTORE_ROOT/$BACKUP_SET_DIR"
        fi
    elif [[ $BACKUP_FILENAME =~ \.zip$ ]] ; then
        echo "Unzipping backupset"
        cd "$RESTORE_ROOT" && unzip -o "$BACKUP_FILENAME"
        
        if [ $? -ne 0 ]; then 
            echo "Failed to unzip target backup set"
            echo "FAILED TO RESTORE $db"
            return
        fi

        # Remove file extension, get to directory name  
        UNZIPPED_BACKUP_DIR=${BACKUP_FILENAME%.zip}

        if [ -z $BACKUP_SET_DIR ] ; then
            echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
            if [ -d "$RESTORE_ROOT/backups" ] ; then
                RESTORE_FROM="$RESTORE_ROOT/backups/$db"
            else
                RESTORE_FROM="$RESTORE_ROOT/data/$db"
            fi
        else
            RESTORE_FROM="$RESTORE_ROOT/$BACKUP_SET_DIR"
        fi
    else
        # If user stores backups as uncompressed directories, we would have pulled down the entire directory
        echo "This backup $BACKUP_FILENAME looks uncompressed."
        RESTORE_FROM="$RESTORE_ROOT/$BACKUP_FILENAME"
    fi

    echo "BACKUP_FILENAME=$BACKUP_FILENAME"
    echo "UNTARRED_BACKUP_DIR=$UNTARRED_BACKUP_DIR"
    echo "UNZIPPED_BACKUP_DIR=$UNZIPPED_BACKUP_DIR"
    echo "RESTORE_FROM=$RESTORE_FROM"

    echo "Set to restore from $RESTORE_FROM - size on disk:"
    du -hs "$RESTORE_FROM"

    # Destination docker directories.
    mkdir -p /data/databases
    mkdir -p /data/transactions

    cd /data && \
    echo "Dry-run command"
    echo neo4j-admin restore \
         --from="$RESTORE_FROM" \
         --database="$db" $FORCE_FLAG \
         --to-data-directory /data/databases/ \
         --to-data-tx-directory /data/transactions/ \
         --move \
         --verbose

    print_volumes_state

    echo "Now restoring"
    neo4j-admin restore \
        --from="$RESTORE_FROM" \
        --database="$db" $FORCE_FLAG \
        --to-data-directory /data/databases/ \
        --to-data-tx-directory /data/transactions/ \
        --move \
        --verbose

    RESTORE_EXIT_CODE=$?

    if [ "$RESTORE_EXIT_CODE" -ne 0 ]; then 
        echo "Restore process failed; will not continue"
        echo "Failed to restore $db"
        print_volumes_state
        return $RESTORE_EXIT_CODE
    fi

    # Modify permissions/group, because we're running as root.
    chown -R neo4j /data/databases 
    chown -R neo4j /data/transactions
    chgrp -R neo4j /data/databases 
    chgrp -R neo4j /data/transactions

    echo "Final permissions"
    ls -al "/data/databases/$db"
    ls -al "/data/transactions/$db"

    echo "Final size"
    du -hs "/data/databases/$db"
    du -hs "/data/transactions/$db"

    if [ "$PURGE_ON_COMPLETE" = true ] ; then
        echo "Purging backupset from disk"
        rm -rf "$RESTORE_ROOT"
    fi

    echo "RESTORE OF $db COMPLETE"
}

function activate_gcp() {
  local credentials="/credentials/credentials"
  if [[ -f "${credentials}" ]]; then
    echo "Activating google credentials before beginning"
    gcloud auth activate-service-account --key-file "${credentials}"
    if [ $? -ne 0 ]; then
      echo "Credentials failed; no way to copy to google."
      exit 1
    fi
  else
    echo "No credentials file found. Assuming workload identity is configured"
  fi
}

function activate_aws() {
  local credentials="/credentials/credentials"
  if [[ -f "${credentials}" ]]; then
    echo "Activating aws credentials before beginning"
    mkdir -p /root/.aws/
    cp /credentials/credentials ~/.aws/config
    if [ $? -ne 0 ]; then
      echo "Credentials failed; no way to copy to aws."
      exit 1
    fi
    aws sts get-caller-identity
    if [ $? -ne 0 ]; then
      echo "Credentials failed; no way to copy to aws."
      exit 1
    fi
  else
    echo "No credentials file found. Assuming IAM Role for Service Account - IRSA is configured"
  fi
}

function activate_azure() {
  echo "Activating azure credentials before beginning"
  source "/credentials/credentials"

  if [ -z $ACCOUNT_NAME ]; then
    echo "You must specify a ACCOUNT_NAME export statement in the credentials secret which is the storage account where backups are stored"
    exit 1
  fi

  if [ -z $ACCOUNT_KEY ]; then
    echo "You must specify a ACCOUNT_KEY export statement in the credentials secret which is the storage account where backups are stored"
    exit 1
  fi
}

echo "=============== Restore ==============================="
echo "CLOUD_PROVIDER=$CLOUD_PROVIDER"
echo "BUCKET=$BUCKET"
echo "TIMESTAMP=$TIMESTAMP"
echo "FORCE_OVERWRITE=$FORCE_OVERWRITE"
echo "PURGE_ON_COMPLETE=$PURGE_ON_COMPLETE"
echo "Starting point database contents: "
ls /data/databases
echo "Starting point transactions: "
ls /data/transactions
echo "============================================================"

case $CLOUD_PROVIDER in
azure)
  activate_azure
  ;;
aws)
  activate_aws
  ;;
gcp)
  activate_gcp
  ;;
*)
  echo "Invalid CLOUD_PROVIDER=$CLOUD_PROVIDER"
  echo "You must set CLOUD_PROVIDER to be one of (aws|gcp|azure)"
  exit 1
  ;;
esac

print_volumes_state

# See: https://neo4j.com/docs/operations-manual/current/backup/restoring/#backup-restoring-cluster
echo "Unbinding previous cluster state, if applicable"
neo4j-admin unbind

# Split by comma
IFS=","
read -a databases <<< "$DATABASE"
for db in "${databases[@]}"; do
   restore_database "$db"
   print_volumes_state
done

echo "All finished"
exit 0

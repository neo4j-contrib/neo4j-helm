# Backing up Neo4j Containers

##Create Secret

####AWS

```
kubectl create secret generic neo4j-aws-credentials \
    -n test-neo4j \
    --from-file=credentials=aws-credentials
```

####GCP

```
kubectl create secret generic neo4j-gcp-credentials \
    -n test-neo4j \
    --from-file=credentials.json=gcp-credentials.json 
```

##Usage 

####AWS

```
helm install my-backup-deployment . \
    --set neo4jaddr=my-neo4j.default.svc.cluster.local:6362 \
    --set bucket=s3://my-bucket \
    --set database="neo4j\,system" \
    --set cloudProvider=aws
```

####GCP

```
helm install my-backup-deployment . \
    --set neo4jaddr=my-neo4j.default.svc.cluster.local:6362 \
    --set bucket=gs://my-bucket \
    --set database="neo4j\,system" \
    --set cloudProvider=gcp
```

[See the Neo4j-Helm User Guide:  Backups](https://neo4j.com/labs/neo4j-helm/1.0.0/backup/) for documentation on this topic.
# Restoring Neo4j Containers

##Create Secret

####AWS

```
kubectl create secret generic neo4j-aws-credentials \
    --from-file=credentials=aws-credentials
```

####GCP

```
kubectl create secret generic neo4j-gcp-credentials \
    --from-file=credentials.json=gcp-credentials.json 
```

##Usage 

####config.yaml
```
neo4jPassword: test123
plugins: "[\"apoc\"]"
core:
  numberOfServers: 3
  persistentVolume:
    storageClass: gp2
    size: 10Gi
  restore:
    enabled: true
    image: gcr.io/neo4j-helm/restore
    imageTag: xxx
    secretName: (neo4j-gcp-credentials|neo4j-aws-credentials)
    database: neo4j,system
    cloudProvider: (gcp|aws)
    bucket: (gs|s3)://test-neo4j
    timestamp: "latest"
    forceOverwrite: true
    purgeOnComplete: true
readReplica:
  numberOfServers: 1
  persistentVolume:
    storageClass: gp2
    size: 10Gi
  restore:
    enabled: true
    image: gcr.io/neo4j-helm/restore
    imageTag: xxx
    secretName: (neo4j-gcp-credentials|neo4j-aws-credentials)
    database: neo4j,system
    cloudProvider: (gcp|aws)
    bucket: (gs|s3)://test-neo4j
    timestamp: "latest"
    forceOverwrite: true
    purgeOnComplete: true
```

```
helm install \
    neo4j neo4j/neo4j \
    -f config.yaml \
    --set acceptLicenseAgreement=yes \
    --version 4.1.1-1
```



[See the Neo4j-Helm User Guide:  Restore](https://neo4j.com/labs/neo4j-helm/1.0.0/restore/) for documentation on this topic.
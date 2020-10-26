#!/bin/sh

NAMESPACE=<YOUR_NEO4J_NAMESPACE>
CREDENTIALS_SECRET=<YOUR_NEO4J_NAMESPACE>

CREDENTIALS=$(cat <<-END
export ACCOUNT_NAME=<NAME_STORAGE_ACCOUNT>
export SUBSCRIPTION=<SUBSCRIPTION_NAME_OR_ID>
export SP_ID=<SERVICE_PRINCIPAL_NAME_OR_ID>
export SP_PASSWORD=<GENERATED_SERVICE_PRINCIPAL_SECRET>
export TENANT_ID=<SERVICE_PRINCIPAL_NAME_OR_ID>
END
)
CREDENTIALS=$(echo $CREDENTIALS | base64)

cat >neo4j-backup-secret.yaml <<EOL
apiVersion: v1
kind: Secret
metadata:
  name: $CREDENTIALS_SECRET
type: Opaque
data:
  credentials: $CREDENTIALS
EOL
kubectl apply -n "$NAMESPACE" -f neo4j-backup-secret.yaml
rm neo4j-backup-secret.yaml

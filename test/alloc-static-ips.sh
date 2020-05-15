#!/bin/bash
# Customize these next 2 for the region of your GKE cluster,
# and your GCP project ID
REGION=us-central1
PROJECT=neo4j-helm

for idx in 0 1 2 ; do 
   gcloud compute addresses create \
      neo4j-static-ip-$idx --project=$PROJECT \
      --network-tier=PREMIUM --region=$REGION

   echo "IP$idx:"
   gcloud compute addresses describe neo4j-static-ip-$idx \
      --region=$REGION --project=$PROJECT --format=json | jq -r '.address'
done

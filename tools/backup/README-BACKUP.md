# Backing up Neo4j Containers

This directory contains files necessary for backing up Neo4j Docker containers
to google storage.

See backup.yaml for an example.   

The "credentials.json" file must be a base64-encoded version of a service key JSON that has permissions to write to the targeted google storage bucket.  The example provided is non-functional, and you must substitute your own.  To determine an appropriate value, perform the following:

- Create a service account with appropriate permissions to write to the google
storage bucket
- Save the key in JSON format to your local disk
- `cat my-key.json | base64`
- Use that resulting value in your `backup.yaml` file
- Finally, after adjusting parameters in backup.yaml, run `kubectl apply -f backup.yaml --namespace my-neo4j-deployed-namespace`

default: docker_build
DOCKER_IMAGE ?= gcr.io/neo4j-helm/tester
DOCKER_TAG ?= 3.0.0

docker_build:
	@docker build \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	  
docker_push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
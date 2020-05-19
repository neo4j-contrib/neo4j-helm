default: docker_build
REGISTRY = gcr.io/neo4j-helm
TEST_IMAGE ?= $(REGISTRY)/tester
BACKUP_IMAGE ?= $(REGISTRY)/backup
RESTORE_IMAGE ?= $(REGISTRY)/restore
DOCKER_TAG ?= 4.0.0

docker_build: 
	docker build \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	  -t $(TEST_IMAGE):$(DOCKER_TAG) -f test/Dockerfile .

	docker build -t $(BACKUP_IMAGE):$(DOCKER_TAG) -f backup/Dockerfile .

	docker build -t $(RESTORE_IMAGE):$(DOCKER_TAG) -f restore/Dockerfile .
	  
docker_push:
	# Push to DockerHub
	docker push $(TEST_IMAGE):$(DOCKER_TAG)
	docker push $(BACKUP_IMAGE):$(DOCKER_TAG)
	docker push $(RESTORE_IMAGE):$(DOCKER_TAG)
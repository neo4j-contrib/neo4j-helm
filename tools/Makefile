default: docker_build
REGISTRY = gcr.io/neo4j-helm
TEST_IMAGE ?= $(REGISTRY)/tester
BACKUP_IMAGE ?= $(REGISTRY)/backup
BUILD_IMAGE ?= $(REGISTRY)/build
RESTORE_IMAGE ?= $(REGISTRY)/restore
DOCKER_TAG ?= `cat ../Chart.yaml | grep version | sed 's/.*: //'`

docker_build: 
	docker build \
	  --build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	  -t $(TEST_IMAGE):$(DOCKER_TAG) -f test/Dockerfile .

	docker build -t $(BACKUP_IMAGE):$(DOCKER_TAG) -f backup/Dockerfile .
	docker build -t $(BUILD_IMAGE):latest -f build/Dockerfile .
	docker build -t $(RESTORE_IMAGE):$(DOCKER_TAG) -f restore/Dockerfile .
	  
docker_push:
	# Push to DockerHub
	docker push $(TEST_IMAGE):$(DOCKER_TAG)
	docker push $(BACKUP_IMAGE):$(DOCKER_TAG)
	docker push $(RESTORE_IMAGE):$(DOCKER_TAG)
	docker push $(BUILD_IMAGE):latest 
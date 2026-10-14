IMAGE ?= trunk-based-cicd-reference
SHA   := $(shell git rev-parse --short HEAD 2>/dev/null || echo local)

.PHONY: test lint run build docker-run smoke

lint:            ## syntax check every Python file
	python3 -m py_compile app/*.py tests/*.py

test: lint       ## run unit tests
	python3 -m unittest discover -s tests -t . -v

run:             ## run the app locally on http://localhost:8080
	python3 -m app.main

build:           ## build the Docker image tagged with the commit SHA
	docker build --build-arg GIT_SHA=$(SHA) -t $(IMAGE):$(SHA) .

docker-run: build
	docker run --rm -p 8080:8080 $(IMAGE):$(SHA)

smoke:           ## start the container and check /health (same as CI)
	./scripts/smoke-test.sh $(IMAGE):$(SHA)

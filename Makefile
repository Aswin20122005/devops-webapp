IMAGE ?= devops-webapp:local
PORT  ?= 8080

.PHONY: build run stop test lint clean

build:  ## Build the Docker image
	docker build -t $(IMAGE) --build-arg GIT_SHA=$$(git rev-parse --short HEAD) \
		--build-arg BUILD_DATE=$$(date -u +%Y-%m-%dT%H:%M:%SZ) .

run: build  ## Run the site on http://localhost:$(PORT)
	docker run -d --rm --name devops-webapp -p $(PORT):8080 $(IMAGE)

stop:  ## Stop the running container
	docker stop devops-webapp

test:  ## Smoke-test the running container
	tests/smoke.sh http://localhost:$(PORT)

lint:  ## Validate HTML and lint the Dockerfile and scripts
	npx --yes html-validate@8 index.html 404.html
	docker run --rm -i hadolint/hadolint < Dockerfile
	shellcheck tests/*.sh

clean: stop
	docker rmi $(IMAGE)

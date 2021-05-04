main: build run

run:
	docker run \
		--interactive \
		--tty \
		--rm \
		"env-ubuntu:latest" \
		"/bin/bash"

build:
	docker build -t env-ubuntu:latest .

rebuild:
	docker build --no-cache -t env-ubuntu:latest .

lint:
	docker pull github/super-linter:latest
	docker run \
		-e RUN_LOCAL=true \
		-e FILTER_REGEX_EXCLUDE='home/.vim/bundle/.*' \
		-v $(shell pwd):/tmp/lint \
		github/super-linter

lint_one:
ifdef file
	docker pull github/super-linter:latest
	docker run \
		-e RUN_LOCAL=true \
		-e FILTER_REGEX_EXCLUDE='home/.vim/bundle/.*' \
		-v $(shell pwd)/$(file):/tmp/lint/$(file) \
		github/super-linter
else
	@echo No file provided
endif

.PHONEY: main build rebuild run lint lint_one

SYMFONY_MAX_DEPRECATED ?= 500
SSH_PATH ?= ~/.ssh/id_rsa

export FPM_UID = $(shell id -u)
export FPM_GID = $(shell id -g)

DOCKER = docker

PHP_BUILD      = $(DOCKER_COMPOSE) run --rm --user="$(shell id -u):$(shell id -g)" build-php
CONSOLE        = $(PHP_BUILD) php bin/console


buildx-build:
	@docker buildx build --tag ghcr.io/adefilippi/build-php7.4:latest --file ./Dockerfile-build --no-cache ./

push-build:
	@docker buildx build --tag ghcr.io/adefilippi/build-php7.4:latest --file ./Dockerfile-build  --push ./

buildx-fpm:
	@docker buildx build --tag ghcr.io/adefilippi/dev-php7.4-fpm:latest --file ./Dockerfile-fpm --no-cache ./

push-fpm:
	@docker buildx build --tag ghcr.io/adefilippi/dev-php7.4-fpm:latest --file ./Dockerfile-fpm --push ./

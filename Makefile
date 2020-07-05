DOCKER_COMPOSE_LOCAL := docker-compose -f ./deploy/docker/docker-compose.yml -f ./deploy/docker/docker-compose.single.yml
DOCKER_COMPOSE_DEV := docker-compose -f ./deploy/docker/docker-compose.yml -f ./deploy/docker/docker-compose.single.yml -f ./deploy/docker/docker-compose.develop.yml

.PHONY: all get-lines dcu dcd dcr dcl dcp dcupd dcupd-dev dcupd-force dcupd-dev-force dcew dctest paratest test db-diff noverify tgd coverage-text platform help

all: test

get-lines: ## Count lines in the project
	@wc -l `find ./src -iname "*.php"` | grep total

dcu: ## Run application in the docker-compose
	$(DOCKER_COMPOSE_LOCAL) up -d

dcd: ## Stop application in the docker-compose
	$(DOCKER_COMPOSE_LOCAL) down

dcdv: ## Stop application in the docker-compose and remove volumes
	$(DOCKER_COMPOSE_LOCAL) down -v

dcr: dcd dcu ## Restart application in the docker-compose
	@echo "Done!"

dcl: ## View logs from docker containers
	$(DOCKER_COMPOSE_LOCAL) logs -f

dcp: ## Get status from docker containers
	$(DOCKER_COMPOSE_LOCAL) ps

dcupd: ## Update application and up
	./deploy/console/local/update-docker.sh $(CI_REGISTRY)

dcupd-dev: ## Update application and up
	./deploy/console/dev/update-docker.sh $(CI_REGISTRY)

dcupd-force: ## Force Update application and up
	$(DOCKER_COMPOSE_LOCAL) stop
	$(DOCKER_COMPOSE_LOCAL) rm -f billing_cba_backend billing_cba_frontend
	docker volume rm -f docker_cba-frontend-data || true
	docker logout $(CI_REGISTRY)
	docker login -u gitlab+deploy-token-3 -p cxE6hXc1XM8XD294UwFf $(CI_REGISTRY)
	$(DOCKER_COMPOSE_LOCAL) pull billing_cba_backend
	docker logout $(CI_REGISTRY)
	docker login -u gitlab+deploy-token-5 -p xezv-qxr1DzcUurS_7cz $(CI_REGISTRY)
	$(DOCKER_COMPOSE_LOCAL) pull billing_cba_frontend
	$(DOCKER_COMPOSE_LOCAL) up -d
	docker logout $(CI_REGISTRY)

dcupd-dev-force: ## Force Update application and up
	$(DOCKER_COMPOSE_DEV) stop
	$(DOCKER_COMPOSE_DEV) rm -f billing_cba_backend billing_cba_frontend
	docker volume rm -f docker_cba-frontend-data || true
	docker logout $(CI_REGISTRY)
	docker login -u gitlab+deploy-token-3 -p cxE6hXc1XM8XD294UwFf $(CI_REGISTRY)
	$(DOCKER_COMPOSE_DEV) pull billing_cba_backend
	docker logout $(CI_REGISTRY)
	docker login -u gitlab+deploy-token-5 -p xezv-qxr1DzcUurS_7cz $(CI_REGISTRY)
	$(DOCKER_COMPOSE_DEV) pull billing_cba_frontend
	$(DOCKER_COMPOSE_DEV) up -d
	docker logout $(CI_REGISTRY)

dcew: dcu ## Connect to billing_web container
	$(DOCKER_COMPOSE_LOCAL) exec billing_web bash

dctest: dcu ## Run tests in the docker containers
	$(DOCKER_COMPOSE_LOCAL) exec billing_web make paratest

test: ## Run tests
	vendor/bin/phpunit --no-coverage

paratest: ## Run tests in parallel processes
	@composer global require "brianium/paratest":"2.*"
	@~/.composer/vendor/bin/paratest -c `pwd`/phpunit.xml --phpunit `pwd`/vendor/bin/phpunit -p 10

db-diff: ## Generate a migration
	bin/gateway doctrine:migrations:diff --env=dev

noverify: ## Run noverify
	@docker run -v `pwd`/src:/project -v `pwd`/output:/tmp/noverify artemy/noverify:latest

platform: ## Make new platform
	@bin/gateway make:platform ${name}

tgd: ## Tails gate dev log
	@tail -f ./app/var/logs/dev.log

tgp: ## Tails gate prod log
	@tail -f ./app/var/logs/prod.log

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


about: ## asd
	@docker-compose exec app php bin/console about

env-vars: ## asd
	@docker-compose exec app php bin/console debug:container --env-vars --show-hidden


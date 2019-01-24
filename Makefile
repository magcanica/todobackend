PROJECT_NAME ?= todobackend
ORG_NAME ?= tatocar
REPO_NAME ?= todobackend


DEV_COMPOSE_FILE := docker/dev/docker-compose.yml
REL_COMPOSE_FILE := docker/release/docker-compose.yml

REL_PROJECT :=$(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(REL_PROJECT)dev

.PHONY: test build release

test:
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) build
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up test
	${INFO} "Testing complete..."

build:
	${INFO} "Building application artifacts..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${INFO} "Copying application artifacts..."
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/. target
	${INFO} "Build complete."
	
release:
	${INFO} "Building images..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) build
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm agent
	${INFO} "Collecting static files..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Runnign database migration..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py migrate --noinput
	${INFO} "Running acceptence tests..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up test 
	${INFO} "Acceptence testing complete..."

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) kill
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) rm -f -v
	${INFO} "Destroying release environment..."
	docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) kill
	docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) rm -f -v
	${INFO} "Removing dangling images..."
	docker images -q -f dangling=true -f label=application=$(REPO_NAME) | xargs -I ARGS docker rmi -f ARGS
	${INFO} "Clean complete."


YELLOW := "\e[1;33m"
NC := "\e[0m"

INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
	printf $(NC)' VALUE
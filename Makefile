# edw-kit — common entry points. Run `make` to list them.
.DEFAULT_GOAL := help

.PHONY: agent docker-build

# 'make agent' → claude (default); 'make agent grok' → grok
AGENT ?= claude
ifeq ($(firstword $(MAKECMDGOALS)),agent)
  _agent_arg := $(word 2,$(MAKECMDGOALS))
  ifneq ($(_agent_arg),)
    AGENT := $(_agent_arg)
    $(eval $(_agent_arg):;@true)
  endif
endif

agent: ## Run an AI agent in Docker. Default: claude. Usage: make agent [grok]
	docker compose run --build --rm $(AGENT)

docker-build: ## Pre-build all agent Docker images
	docker compose build

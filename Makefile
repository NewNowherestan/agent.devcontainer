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

# Extra flags for `docker compose run`, meant for port publishes. Empty by
# default: `make agent` from THIS directory exposes no ports (chat-only, no
# host-port conflicts across laptops). A parent project's root Makefile passes
# e.g. PUBLISH="--publish 8088:8080" to expose project UIs from up there.
PUBLISH ?=

agent: ## Run an AI agent in Docker (no ports here; parent Makefile passes PUBLISH=). Default: claude. Usage: make agent [grok]
	docker compose run $(PUBLISH) --build --rm $(AGENT)

docker-build: ## Pre-build all agent Docker images
	docker compose build

ifeq (release, $(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
  $(eval $(ARGS):;@true)
endif

# help: @ Lists available make tasks
help:
	@egrep -oh '[0-9a-zA-Z_\.\-]+:.*?@ .*' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

# clean: @ Cleans the build output directories
.PHONY: clean
clean:
	rm -Rf ./build/site
	rm -Rf ./build/cache
	
# install: @ Installs asciidoctor extensions
install:
	docker-compose run antora npm install asciidoctor asciidoctor-kroki

# build: @ Builds documentation production output (to build/site)
build: PLAYBOOK ?= content
build: clean 
	docker-compose run -u $$(id -u) antora antora generate antora-playbook.$(PLAYBOOK).yml

# preview: @ Serves content on port 8081
preview: PLAYBOOK ?= content
preview: build
	docker-compose run --service-ports antora http-server build/site -c-1

# watch: @ Watches for documentation changes and rebuilds (to build/site)
watch:
	docker-compose run -u $$(id -u) -T antora onchange \
	-i module-playbook.yml 'content/**' \
	-- antora generate module-playbook.yml

# shell: @ Opens bash shell in antora container
shell: CMD ?= /bin/sh
shell:
	docker-compose run -u $$(id -u) antora $(CMD)

# ui: @ Install the latest UI theme bundle
prompt_for_token = echo Enter Github auth token:; read GITHUB_AUTH_TOKEN
ui: GITHUB_AUTH_TOKEN ?= 
ui:
	$(if $(GITHUB_AUTH_TOKEN),GITHUB_AUTH_TOKEN=$(GITHUB_AUTH_TOKEN),$(prompt_for_token))
	CURL="curl -v -H 'Authorization: token $$GITHUB_AUTH_TOKEN' \
	      https://api.github.com/repos/wethinkcode/antora-docs-ui/releases"; \
	ASSET_ID=$$(eval "$$CURL/latest" | jq .assets[0].id); \
	eval "$$CURL/assets/$$ASSET_ID -o tmp/ui-bundle.zip -LJH 'Accept: application/octet-stream'"j

# release: @ Copy the folders in the specified release outline from content to release (e.g. make release 5)
.PHONY: release
release: RELEASE ?= $(ARGS)
release: DIRECTORY ?= $(shell pwd)
release:
	rm -rf ./release/modules/*
	rm -f ./release/nav.adoc
	cd content/modules ; \
	while read -r module ; \
		do \
		cp -r --parents $$module $(DIRECTORY)/release/modules ; \
	done < $(DIRECTORY)/release-outline/release-$(RELEASE).txt
	cp $(DIRECTORY)/release-outline/nav-$(RELEASE).adoc $(DIRECTORY)/release/nav.adoc

# tools: @ Update the tools from the curriculum-tools repository
.PHONY: tools
tools: 
	git remote -v | grep -w tools && \
	git remote set-url tools git@github.com:wethinkcode/curriculum-tools.git || \
	git remote add tools git@github.com:wethinkcode/curriculum-tools.git
	git pull tools main --allow-unrelated-histories


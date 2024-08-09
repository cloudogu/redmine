MAKEFILES_VERSION=9.1.0

.DEFAULT_GOAL:=dogu-release

include build/make/variables.mk
include build/make/self-update.mk
include build/make/release.mk
include build/make/bats.mk
include build/make/version-sha.mk

CAS_PLUGIN_VERSION=v$(shell grep CAS_PLUGIN_VERSION= Dockerfile | sed 's/.*CAS_PLUGIN_VERSION=\([^ ]*\).*/\1/g')
CLOUDOGU_THEME_VERSION=$(shell grep CLOUDOGU_THEME_VERSION= Dockerfile | sed 's/.*CLOUDOGU_THEME_VERSION=\([^ ]*\).*/\1/g')
SESSION_STORE_VERSION=v$(shell grep ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION= Dockerfile | sed 's/.*ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION=\([^ ]*\).*/\1/g')
API_PLUGIN_VERSION=v$(shell grep EXTENDED_REST_API_PLUGIN_VERSION= Dockerfile | sed 's/.*EXTENDED_REST_API_PLUGIN_VERSION=\([^ ]*\).*/\1/g')
RUBYCAS_VERSION=v$(shell grep RUBYCASVERSION= Dockerfile | sed 's/.*RUBYCASVERSION=\([^ ]*\).*/\1/g')
REDMINE_VERSION=$(shell grep REDMINE_VERSION= Dockerfile | sed 's/.*REDMINE_VERSION=\([^ ]*\).*/\1/g')

.PHONY: sums
sums: ## Print out all versions
	@echo "Cas Plugin"
	@make --no-print-directory sha-sum SHA_SUM_REPOSITORY=redmine_cas SHA_SUM_VERSION=${CAS_PLUGIN_VERSION}
	@echo "Cloudogu Theme"
	@make --no-print-directory sha-sum SHA_SUM_URL="https://github.com/cloudogu/PurpleMine2/releases/download/v${CLOUDOGU_THEME_VERSION}/CloudoguRedmineTheme-${CLOUDOGU_THEME_VERSION}.tar.gz"
	@echo "Sessionstore Plugin"
	@make --no-print-directory sha-sum SHA_SUM_REPOSITORY=redmine_activerecord_session_store SHA_SUM_VERSION=${SESSION_STORE_VERSION}
	@echo "Rest API Plugin"
	@make --no-print-directory sha-sum SHA_SUM_REPOSITORY=redmine_extended_rest_api SHA_SUM_VERSION=${API_PLUGIN_VERSION}
	@echo "Rubycas-client-version"
	@make --no-print-directory sha-sum SHA_SUM_REPOSITORY=rubycas-client SHA_SUM_VERSION=${RUBYCAS_VERSION}
	@echo "Redmine-client-version"
	@make --no-print-directory sha-sum SHA_SUM_URL="https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz"
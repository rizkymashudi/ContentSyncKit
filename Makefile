.DEFAULT_GOAL := help
SHELL := /bin/bash

EXAMPLE_PROJ ?= Example/ContentKitExample.xcodeproj
EXAMPLE_SCHEME ?= ContentKitExample
DESTINATION  ?= generic/platform=iOS Simulator
SECRET_RE   := \.env|\.xcconfig|GoogleService-Info\.plist|secrets?\.(json|plist|ya?ml)|\.p8|\.p12|\.mobileprovision|\.pem|id_rsa

.PHONY: help build test lint verify verify-example check-secrets clean

help: ## List available targets
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk -F':.*?## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

build: ## Build the package
	swift build

test: ## Run the package test suite
	swift test

lint: ## Lint with SwiftLint (strict). Skipped with a warning if not installed.
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --strict; \
	else \
		echo "swiftlint not installed — skipping. brew install swiftlint"; \
	fi

check-secrets: ## Fail if tracked files look like credentials
	@matches=$$(git ls-files | grep -E '$(SECRET_RE)' || true); \
	if [ -n "$$matches" ]; then \
		echo "Credential-shaped files are tracked by git:"; \
		echo "$$matches" | sed 's/^/  /'; \
		echo "Remove them from the index and add them to .gitignore."; \
		exit 1; \
	fi; \
	echo "check-secrets: clean"

verify: build test lint check-secrets ## Everything an agent must run before claiming done
	@echo "verify: all checks passed"

verify-example: ## Build the demo app (only when your change touches it)
	xcodebuild build -project "$(EXAMPLE_PROJ)" -scheme "$(EXAMPLE_SCHEME)" \
		-destination "$(DESTINATION)" -quiet

clean: ## Remove build artifacts
	swift package clean

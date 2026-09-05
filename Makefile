# Makefile — the single entry point for every dev/CI task.
# Run `make` or `make help` to list targets. CI runs the same targets you run locally.
#
# Conventions:
#   - Godot's version is pinned in .godot-version. The CI container tags must match it;
#     both workflows fail loudly if they drift.
#   - Targets that need imported resources depend on `import` (Godot's .godot/ cache
#     is git-ignored, so a fresh clone or CI runner must import before test/export).
#   - Logs land in reports/ (git-ignored).

SHELL := /usr/bin/env bash
# NOTE: macOS ships GNU make 3.81, which ignores .SHELLFLAGS, so piped recipe lines set
# `set -o pipefail` explicitly; otherwise `godot ... | tee` would hide Godot's exit code.
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

GODOT ?= godot
GODOT_VERSION := $(shell cat .godot-version)
GD_DIRS := game tests scripts
GUT_ARGS ?=
WEB_PORT ?= 8060
WEB_BIND ?= 127.0.0.1
BUILD_DIR := build

.PHONY: help setup version import check lint format test run export-web export-all serve-web clean ci

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Single test:  make test GUT_ARGS=\"-gselect=test_game_rules -gunit_test_name=test_add_score\""
	@echo "  Warnings you want enforced must be level 2 (error) in project.godot; Godot prints no level-1 warnings headlessly."

setup: ## Install Godot, gdtoolkit, pre-commit and export templates (macOS)
	./scripts/setup.sh

version: ## Verify the installed Godot matches .godot-version
	@$(GODOT) --version | grep -q "^$(GODOT_VERSION)\." || { echo "ERROR: need Godot $(GODOT_VERSION), found: $$($(GODOT) --version)"; exit 1; }
	@echo "Godot $(GODOT_VERSION) OK"

import: ## Import resources into .godot/ (required after clone and whenever assets change)
	@mkdir -p reports && touch reports/.gdignore
	set -o pipefail; $(GODOT) --headless --path . --import 2>&1 | tee reports/import.log
	@! grep -E "ERROR:.*res://(game|tests)" reports/import.log

check: import ## Load+compile every script and scene in game/ and tests/; fail on any error (incl. error-level warnings)
	set -o pipefail; $(GODOT) --headless --path . -s scripts/check_scripts.gd 2>&1 | tee reports/check.log
	@! grep -E "SCRIPT ERROR|Parse Error|CHECK FAILED|ERROR:.*res://(game|tests)" reports/check.log
	@echo "check OK"

lint: ## gdformat --check + gdlint on game/ and tests/
	gdformat --check $(GD_DIRS)
	gdlint $(GD_DIRS)

format: ## Rewrite GDScript files with gdformat
	gdformat $(GD_DIRS)

test: import ## Run the GUT test suite headless (JUnit XML -> reports/results.xml)
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gexit $(GUT_ARGS) 2>&1 | tee reports/test.log
	@# GUT exits 0 when a test *script* fails to parse, and when zero tests run. Close both holes.
	@! grep -E "Failed to load script|SCRIPT ERROR|Parse Error|\[GUT ERROR\]" reports/test.log
	@test -f reports/results.xml || { echo "ERROR: reports/results.xml missing - did any tests run?"; exit 1; }
	@grep -qE '<testsuites[^>]* tests="[1-9][0-9]*"' reports/results.xml || { echo "ERROR: no tests ran"; exit 1; }
	@! grep -qE '<testsuites[^>]* (failures|errors)="[1-9]' reports/results.xml

run: import ## Run the game (main scene) in a window
	$(GODOT) --path .

export-web: version import ## Export the Web build to build/web/
	@mkdir -p $(BUILD_DIR)/web && touch $(BUILD_DIR)/.gdignore
	$(GODOT) --headless --path . --export-release "Web" $(BUILD_DIR)/web/index.html

export-all: export-web ## Export Web + Windows + Linux + macOS builds to build/
	@mkdir -p $(BUILD_DIR)/windows $(BUILD_DIR)/linux $(BUILD_DIR)/macos
	$(GODOT) --headless --path . --export-release "Windows Desktop" $(BUILD_DIR)/windows/weird-world.exe
	$(GODOT) --headless --path . --export-release "Linux/X11" $(BUILD_DIR)/linux/weird-world.x86_64
	$(GODOT) --headless --path . --export-release "macOS" $(BUILD_DIR)/macos/weird-world.zip

serve-web: ## Serve build/web/ on http://localhost:8060, localhost only (WEB_PORT=, WEB_BIND= to override)
	@echo "Open http://localhost:$(WEB_PORT)  (Ctrl+C to stop)"
	python3 -m http.server $(WEB_PORT) --bind $(WEB_BIND) --directory $(BUILD_DIR)/web

clean: ## Remove generated files (.godot/, build/, reports/)
	rm -rf ./.godot ./build ./reports

ci: version lint check test ## Exactly what CI's test job runs: version, lint, check, test

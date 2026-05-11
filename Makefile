# Makefile for walter-ai-engineering-book
#
# Flat layout: Sphinx sources in ./source, Poetry metadata at the root,
# build output in ./build. The Poetry virtualenv lives at ./.venv
# (configured via poetry.toml: virtualenvs.in-project = true).
#
# Every build / serve / lint target is routed through `poetry run` so the
# toolchain never pollutes the ambient Python. When called from inside
# `poetry shell` / `poetry env activate` (POETRY_ACTIVE=1) the `poetry run`
# prefix is stripped automatically, so `make html` works either way.
#
# Quick start:
#
#   make install          # poetry install (one-time)
#   make html             # sphinx-build (strict)
#   make serve            # serve build/html/ at http://localhost:7800
#   make livehtml         # live-reload preview via sphinx-autobuild
#   make lint             # sphinx linkcheck (dead-link detection)
#   make clean            # remove build/
#   make check            # lint + html (CI entry point)
#   make publish          # build + force-push build/html/ to gh-pages
#
# Every short target is mirrored as `book-<name>` for compatibility with
# external callers / prior docs that used a delegator layout.

# Default: non-strict so authoring warnings don't break the build while the
# book is in draft. Re-enable strict mode any time with:
#     make html SPHINXOPTS="-W --keep-going -n"
# Once the content is clean, change the default below to "-W --keep-going -n"
# and CI will start failing on new warnings (recommended for finished books).
SPHINXOPTS      ?= --keep-going -n
# Bare commands here: `ifndef POETRY_ACTIVE` below prepends `poetry run` once.
SPHINXBUILD     ?= sphinx-build
SPHINXAUTOBUILD ?= sphinx-autobuild
SOURCEDIR       ?= source
BUILDDIR        ?= build
PORT            ?= 7800
HOST            ?= 127.0.0.1

# Auto-wrap every tool invocation in `poetry run` unless we are already
# inside the venv (Poetry exports POETRY_ACTIVE=1 in that case).
POETRY          ?= poetry
ifndef POETRY_ACTIVE
SPHINXBUILD     := $(POETRY) run $(SPHINXBUILD)
SPHINXAUTOBUILD := $(POETRY) run $(SPHINXAUTOBUILD)
PY              := $(POETRY) run python
else
PY              := python
endif

.DEFAULT_GOAL := help

.PHONY: help check \
        install export-requirements shell \
        clean \
        html pdf \
        livehtml serve \
        lint linkcheck \
        publish publish-status \
        book-install book-export-requirements book-shell \
        book-clean \
        book-html book-pdf \
        book-livehtml book-serve \
        book-lint book-linkcheck \
        book-publish book-publish-status

help: ## Show available targets
	@echo 'walter-ai-engineering-book — Sphinx build targets (auto-wrapped in `poetry run`)'
	@echo ''
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z][a-zA-Z0-9_-]*:.*?## / {printf "  %-26s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Tunable variables:  PORT=$(PORT)  HOST=$(HOST)  SPHINXOPTS="$(SPHINXOPTS)"'

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

install: ## Create/refresh the Poetry virtualenv (./.venv)
	$(POETRY) install --with dev
	@echo "  -> poetry env ready at $$($(POETRY) env info --path 2>/dev/null || echo .venv)"

export-requirements: ## Refresh requirements.txt from poetry.lock (pip fallback)
	@$(POETRY) self show plugins 2>/dev/null | grep -q poetry-plugin-export \
		|| { echo "  !! poetry-plugin-export not installed."; \
		     echo "     install it once with:  poetry self add poetry-plugin-export"; \
		     exit 1; }
	$(POETRY) export --without-hashes -f requirements.txt -o requirements.txt
	@echo "  -> wrote requirements.txt"

shell: ## Drop into a sub-shell with the venv activated
	@if $(POETRY) env activate --help >/dev/null 2>&1; then \
		$(POETRY) env activate; \
	elif $(POETRY) shell --help >/dev/null 2>&1; then \
		$(POETRY) shell; \
	else \
		echo "  !! neither 'poetry env activate' nor 'poetry shell' is available."; \
		echo "     install the shell plugin:  poetry self add poetry-plugin-shell"; \
		exit 1; \
	fi

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

clean: ## Remove build/ output
	rm -rf "$(BUILDDIR)"

html: ## Build the HTML tree at build/html/ (strict)
	$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS)

pdf: ## Build a PDF via LaTeX at build/latex/ (requires xelatex + xeCJK)
	$(SPHINXBUILD) -M latexpdf "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS)
	@echo "  -> PDF in $(BUILDDIR)/latex/"

# ---------------------------------------------------------------------------
# Preview & serve
# ---------------------------------------------------------------------------

livehtml: ## Serve the build with auto-reload on change (sphinx-autobuild)
	$(SPHINXAUTOBUILD) --host $(HOST) --port $(PORT) "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS)

serve: ## Serve build/html/ statically at http://$(HOST):$(PORT)/
	@if [ ! -d "$(BUILDDIR)/html" ]; then \
		echo "  !! $(BUILDDIR)/html/ does not exist — run 'make html' first"; \
		exit 1; \
	fi
	@echo "  -> serving $(BUILDDIR)/html/ at http://$(HOST):$(PORT)/"
	@echo "     (Ctrl-C to stop)"
	$(PY) -m http.server $(PORT) --bind $(HOST) --directory "$(BUILDDIR)/html"

# ---------------------------------------------------------------------------
# Quality gates
# ---------------------------------------------------------------------------

# No project-specific lint script yet; map `lint` to sphinx linkcheck so the
# CI 'check' target still does something useful (catches dead URLs).
lint: linkcheck ## Run lint (currently == linkcheck)

linkcheck: ## Report dead external links without failing the html build
	$(SPHINXBUILD) -b linkcheck "$(SOURCEDIR)" "$(BUILDDIR)/linkcheck"

check: lint html ## Lint + full build (used by CI)

# ---------------------------------------------------------------------------
# Publish to GitHub Pages (gh-pages branch approach)
# ---------------------------------------------------------------------------
#
# Build the HTML locally with `make html`, then force-push the build output
# onto a dedicated `gh-pages` branch of the GitHub remote. GitHub Pages on
# the repo must be set to:
#
#   Settings -> Pages -> Source: "Deploy from a branch"
#                         Branch: gh-pages / (root)

PUBLISH_REMOTE      ?= origin
PUBLISH_PAGES_BRANCH?= gh-pages
# Pull the github.com slug (owner/repo) out of the remote URL — supports
# both git@github.com:owner/repo.git and https://github.com/owner/repo(.git).
PUBLISH_SLUG        ?= $(shell git remote get-url $(PUBLISH_REMOTE) 2>/dev/null | sed -E -e 's|^git@github\.com:||' -e 's|^https?://github\.com/||' -e 's|\.git$$||')
PUBLISH_OWNER       ?= $(firstword $(subst /, ,$(PUBLISH_SLUG)))
PUBLISH_REPO        ?= $(lastword $(subst /, ,$(PUBLISH_SLUG)))

publish: html ## Build, then force-push build/html/ to the gh-pages branch
	@if [ ! -d "$(BUILDDIR)/html" ]; then \
		echo "  !! $(BUILDDIR)/html/ missing after 'make html'"; exit 1; \
	fi
	@REMOTE_URL="$$(git remote get-url $(PUBLISH_REMOTE) 2>/dev/null)"; \
	if [ -z "$$REMOTE_URL" ]; then \
		echo "  !! could not resolve remote '$(PUBLISH_REMOTE)'"; exit 1; \
	fi; \
	TMPDIR="$$(mktemp -d)"; \
	trap 'rm -rf "$$TMPDIR"' EXIT; \
	cp -R "$(BUILDDIR)/html/." "$$TMPDIR/"; \
	touch "$$TMPDIR/.nojekyll"; \
	echo "  -> publishing $(BUILDDIR)/html/ to $$REMOTE_URL ($(PUBLISH_PAGES_BRANCH))"; \
	cd "$$TMPDIR" && \
		git init -q && \
		git checkout -q -b "$(PUBLISH_PAGES_BRANCH)" && \
		git add -A && \
		git -c user.name="$$(git -C "$(CURDIR)" config user.name)" \
		    -c user.email="$$(git -C "$(CURDIR)" config user.email)" \
		    commit -q -m "publish: $$(date -u +%Y-%m-%dT%H:%M:%SZ)" && \
		git push --force "$$REMOTE_URL" "$(PUBLISH_PAGES_BRANCH):$(PUBLISH_PAGES_BRANCH)"
	@echo ""
	@echo "  -> deployed site:  https://$(PUBLISH_OWNER).github.io/$(PUBLISH_REPO)/"
	@echo "     (first publish? enable Pages: https://github.com/$(PUBLISH_SLUG)/settings/pages"
	@echo "      -> Source: 'Deploy from a branch' -> Branch: '$(PUBLISH_PAGES_BRANCH)' / root)"

publish-status: ## Print URLs for the Pages settings, gh-pages branch, and deployed site
	@if [ -z "$(PUBLISH_SLUG)" ]; then \
		echo "  !! could not detect github.com slug from remote '$(PUBLISH_REMOTE)'"; \
		exit 1; \
	fi
	@echo "  Pages settings:  https://github.com/$(PUBLISH_SLUG)/settings/pages"
	@echo "  gh-pages branch: https://github.com/$(PUBLISH_SLUG)/tree/$(PUBLISH_PAGES_BRANCH)"
	@echo "  Deployed site:   https://$(PUBLISH_OWNER).github.io/$(PUBLISH_REPO)/"

# Compatibility aliases for callers that use the book-* target names.
book-install: install
book-export-requirements: export-requirements
book-shell: shell
book-clean: clean
book-html: html
book-pdf: pdf
book-livehtml: livehtml
book-serve: serve
book-lint: lint
book-linkcheck: linkcheck
book-publish: publish
book-publish-status: publish-status

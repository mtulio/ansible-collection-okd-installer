VENV_DOCS ?= ./.venv-docs
VENV_REQ ?= docs/requirements.txt
MKDOCS_ARGS ?= -f ./mkdocs.yaml
INSTALL_CMD ?= yum

.PHONY: venv
venv:
	test -d $(VENV_DOCS) || python3 -m venv $(VENV_DOCS)

.PHONY: requirements
requirements: venv
	$(VENV_DOCS)/bin/pip3 install --upgrade pip
	$(VENV_DOCS)/bin/pip3 install -r $(VENV_REQ)

# Vercel
.PHONY: ci-dependencies
ci-dependencies:
	cat /etc/os-release
	$(INSTALL_CMD) install -y python3-pip graphviz

.PHONY: ci-install
docs-ci-install: ci-dependencies requirements

docs-serve:
	$(VENV_DOCS)/bin/mkdocs serve $(MKDOCS_ARGS)

docs-build:
	$(VENV_DOCS)/bin/mkdocs build $(MKDOCS_ARGS)

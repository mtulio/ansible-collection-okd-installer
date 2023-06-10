VENV_DOCS ?= ./.venv-docs
VENV_REQ ?= docs/requirements.txt
MKDOCS_ARGS ?= -f ./mkdocs.yaml
INSTALL_CMD ?= yum

.PHONY: docs-install
docs-install:
	hack/docs.sh install

.PHONY: docs-build
docs-build:
	hack/docs.sh build

docs-build:
	hack/docs.sh build

docs-serve:
	hack/docs.sh serve


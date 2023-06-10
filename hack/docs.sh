#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

OPT=$1; shift
MKDOCS_ARGS="-f ./mkdocs.yaml"
VENV_DOCS="/tmp/venv-docs"

setup() {
    python3.9 -m venv ${VENV_DOCS}
}

install() {
    if [[ -x "$(which yum)" ]]; then
        yum install -y python3-pip graphviz
    else
        sudo apt update
        sudo apt install -y python3-pip graphviz
    fi
    pip3 install --upgrade pip
    pip3 install -r docs/requirements.txt
}

build() {
    mkdocs build ${MKDOCS_ARGS}
}

serve() {
    mkdocs serve ${MKDOCS_ARGS}
}

case $OPT in
    "setup") setup ;;
    "install") install ;;
    "build") build ;;
    "serve") serve ;;
esac
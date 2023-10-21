# Installing a cluster quickly on OCI with platform agnostic (None)

The steps below describes how to validate the OpenShift cluster installed
in an agnostic installation using standard topology.

## Prerequisites

--8<-- "docs/modules/pre-env-creds-aws.md"

## Setup

--8<-- "docs/modules/pre-env-distributions.md"

### Export the emvironment variables for cloud provider

--8<-- "docs/modules/pre-env-aws-none.md"
--8<-- "docs/modules/pre-env-cfg.md"

### Create the okd-installer var file

--8<-- "docs/modules/pre-cfg-varfile.md"

- Discovery the AMI:

```bash
DISTRIBUTION="ocp"
RELEASE_REPO="quay.io/openshift-release-dev/ocp-release"
VERSION="4.14.0-rc.6"
#RELEASE_VERSION="${VERSION}-x86_64"
PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"

# Provider Information
export CONFIG_PROVIDER=aws
export CONFIG_PLATFORM=none

# Cluster Install Configuration
CLUSTER_NAME="aws-n412rc6a0"
CLUSTER_REGION=us-east-1
CLUSTER_DOMAIN="devcluster.openshift.com"
VARS_FILE=./vars_${DISTRIBUTION}-${CLUSTER_NAME}.yaml

# okd-installer config
cat <<EOF > ${VARS_FILE}
provider: ${CONFIG_PROVIDER}
config_platform: ${CONFIG_PLATFORM}
cluster_name: ${CLUSTER_NAME}
config_cluster_region: ${CLUSTER_REGION}

config_cluster_version: ${VERSION}
version: ${VERSION}

config_default_architecture: arm64
controlplane_instance: m6g.xlarge
compute_instance: m6g.xlarge

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: ${CLUSTER_DOMAIN}
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${PULL_SECRET_FILE}"
EOF

# Install the clients (installer) and extract the image ID from stream information.
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE

IMAGE_ID=$(~/.ansible/okd-installer/bin/openshift-install-linux-${VERSION} coreos print-stream-json | jq -r ".architectures[\"aarch64\"].images.aws.regions[\"$CLUSTER_REGION\"].image")

cat <<EOF >> ${VARS_FILE}
custom_image_id: ${IMAGE_ID}
EOF

# create the cluster
ansible-playbook mtulio.okd_installer.create_all \
    -e cert_max_retries=30 \
    -e cert_wait_interval_sec=60 \
    -e @$VARS_FILE
```

## Install

--8<-- "docs/modules/play-create_all.md"

--8<-- "docs/modules/play-approve_certs.md"

## Destroy

--8<-- "docs/modules/play-destroy_cluster.md"
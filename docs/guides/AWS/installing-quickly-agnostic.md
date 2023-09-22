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
cat <<EOF > ${VARS_FILE}
# discovery AMI ID: ~/.ansible/okd-installer/bin/openshift-install-linux-4.14.0-rc.0 coreos print-stream-json | jq -r '.architectures.x86_64.images.aws.regions["us-east-1"].image'
custom_image_id: ami-0a4a3456fc86deabc
EOF
```



## Install

--8<-- "docs/modules/play-create_all.md"

--8<-- "docs/modules/play-approve_certs.md"

## Destroy

--8<-- "docs/modules/play-destroy_cluster.md"
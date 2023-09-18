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

## Install

--8<-- "docs/modules/play-create_all.md"

--8<-- "docs/modules/play-approve_certs.md"

## Destroy

--8<-- "docs/modules/play-destroy_cluster.md"
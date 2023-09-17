
The steps below describes how to validate the OpenShift cluster installed
in an agnostic installation using standard topology.

## Prerequisites

--8<-- "docs/modules/cfg-env-cluster-aws.md"

--8<-- "docs/modules/cfg-env-distribution-okdscos.md"

--8<-- "docs/modules/cfg-okdc-varfile.md"

## Install

--8<-- "docs/modules/play-create_all.md"

--8<-- "docs/modules/play-approve_certs.md"

## Destroy

--8<-- "docs/modules/play-destroy_cluster.md"
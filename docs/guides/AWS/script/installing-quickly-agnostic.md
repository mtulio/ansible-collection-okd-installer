# Installing a cluster quickly on OCI with platform agnostic (None)

Script containing all steps described in the guide.

## Requirements

```bash
--8<-- "docs/modules/pre-env-creds-aws.sh"
```

## Install

```bash
--8<-- "docs/modules/pre-env-distribution-ocp.sh"

--8<-- "docs/modules/pre-env-aws-none.sh"

--8<-- "docs/modules/pre-env-cfg.sh"

--8<-- "docs/modules/pre-cfg-varfile.sh"

--8<-- "docs/modules/play-create_all.sh"
```

## Destroy

```bash
--8<-- "docs/modules/play-destroy_cluster.sh"
```
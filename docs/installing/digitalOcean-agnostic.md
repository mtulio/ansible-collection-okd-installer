# OKD Install on DigitalOcean provider with platform agnostic

> NOTE/ToDo: Outdated documentation. Need to be reviewed

### Create an OpenShift cluster on DigitalOcean with no integration (platform=None)

Authentication:
- Create an [Token](https://cloud.digitalocean.com/account/api/tokens)
- Export it: `export DO_API_TOKEN=value`
- Alternatively, setup the CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- Install ansible collection for DO
- Install the collection (it's constantly updating)
```
ansible-galaxy collection install community.digitalocean
```

Targets available:
- Gen Config
```bash
INSTALL_DIR="${PWD}/.install-dir-mrbdo"
make clean INSTALL_DIR=${INSTALL_DIR}
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${INSTALL_DIR}" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e custom_image_id=fedora-coreos-34.20210626.3.1-digitalocean.x86_64.qcow2.gz -e config_platform="" -vvv' \
    CONFIG_BASE_DOMAIN="splat-do.devcluster.openshift.com" \
    $(which time) -v make openshift-config
```

- Config load
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e config_platform="" -vvv' \
    $(which time) -v make openshift-config-load
```

- Create Network Stack
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS="-e config_platform="" -vvv -e region=${CONFIG_REGION}" \
    $(which time) -v make openshift-stack-network
```

- Create DNS
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e config_platform="" -vvv' \
    $(which time) -v make openshift-stack-dns
```


- Create Load Balancers
> DO LB is limited the HC by LB, not rule, so it can be a problem
> when specific service goes down. Recommened is to create one LB by
> rule with proper health check (not cover here)
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e config_platform="" -vvv' \
    $(which time) -v make openshift-stack-loadbalancers
```


- Bootstrap setup
> ny{1,2} region is crashing on Spaces API.
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e config_platform="" -vvv' \
    $(which time) -v make openshift-bootstrap-setup
```

- Bootstrap create
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    CONFIG_REGION="nyc3" \
    EXTRA_ARGS='-e config_platform="" -vvv' \
    $(which time) -v make openshift-stack-bootstrap
```


- Destroy the resources
```bash
CONFIG_CLUSTER_NAME=mrbdo \
    CONFIG_PROVIDER="do" \
    CONFIG_REGION="nyc3" \
    INSTALL_DIR="${PWD}/.install-dir-mrbdo" \
    EXTRA_ARGS='-vvv' \
    make openshift-destroy
```



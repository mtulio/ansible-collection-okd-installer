# OKD Install on AWS provider with platform agnostic

> NOTE/ToDo: Outdated documentation. Need to be reviewed

### Create an OpenShift cluster on AWS with no integration (platform=None)

Create the cluster:
```bash
INSTALL_DIR="${PWD}/.install-dir-mrbnone"
make clean INSTALL_DIR=${INSTALL_DIR}
CONFIG_CLUSTER_NAME=mrbnone \
    INSTALL_DIR="${INSTALL_DIR}" \
    CONFIG_PROVIDER=aws \
    EXTRA_ARGS='-e custom_image_id=ami-0a57c1b4939e5ef5b -e config_platform="" -vvv -e compute_instance=m6i.xlarge' \
    $(which time) -v make openshift-install
```

- Approve the certificates to Compute nodes join to the cluster
```bash
for i in $(oc --kubeconfig ${INSTALL_DIR}/auth/kubeconfig \
            get csr --no-headers    | \
            grep -i pending         | \
            awk '{ print $1 }')     ; do \
    oc --kubeconfig ${INSTALL_DIR}/auth/kubeconfig \
        adm certificate approve $i; \
done
```

Create the Load Balancers for default router on AWS:

```bash
INSTALL_DIR=${INSTALL_DIR} \
    CONFIG_PROVIDER=aws \
    make openshift-stack-loadbalancers-none
```

Check the COs

```bash
oc --kubeconfig ${INSTALL_DIR}/auth/kubeconfig get co -w
```

Destroy a cluster (Ingress Load balancer then cluster resources):

```bash
# Destroy the ingress LB first
INSTALL_DIR=${INSTALL_DIR} \
    CONFIG_PROVIDER=aws \
    EXTRA_ARGS='-t loadbalancer' \
    make openshift-destroy-loadbalancers-none

# Destroy the cluster
INSTALL_DIR=${INSTALL_DIR} \
    CONFIG_PROVIDER=aws \
    EXTRA_ARGS='-vvv' \
    make openshift-destroy
```

Clear install-dir
```bash
make clean INSTALL_DIR=${INSTALL_DIR}
```


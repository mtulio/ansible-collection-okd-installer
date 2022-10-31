# OKD Install on AWS provider with platform agnostic

> NOTE/ToDo: Outdated documentation. Need to be reviewed


### Prepare the environment

#### Export the environment variables used to create the cluster

Create `.env-none` file or just export it to your session:

```bash
cat <<EOF> .env-none
export CONFIG_CLUSTER_NAME=mrbnone
export CONFIG_PROVIDER=aws
export CONFIG_BASE_DOMAIN=devcluster.openshift.com
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF

source ./.env-none
```

Load it:
```bash
source .env-none
```

Check if all required variables has been set:

```bash
ansible-playbook  mtulio.okd_installer.config \
    -e mode=check-vars \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Config

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e custom_image_id=ami-0a57c1b4939e5ef5b \
    -e config_platform="" \
    -e compute_instance=m6i.xlarge \
    -vvv
```


## (old stpes) Create an OpenShift cluster on AWS with no integration (platform=None)

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


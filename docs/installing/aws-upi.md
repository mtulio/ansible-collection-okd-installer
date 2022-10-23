# OKD Install on AWS provider with UPI

Steps to install OKD/OCP clusters in AWS with user-provisioned infrastructure, with Ansible as IaaC to provision the infrastructure.

## Build-in Use Cases

The use cases described below are re-using playbooks
changing the variables for each goal.

Feel free to look into the Makefile and create your own
customization re-using the playbooks to install k8s/okd/openshift
clusters.

### Prepare the environment

#### Export the environment variables used to create the cluster

Create `.env` file or just export it to your session:

- `platform.none: {}`
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

- `platform.aws: {}`

```bash
cat <<EOF> .env-aws
export CONFIG_CLUSTER_NAME=mrbaws
export CONFIG_PROVIDER=aws
export CONFIG_PLATFORM=aws
export CONFIG_BASE_DOMAIN=devcluster.openshift.com
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF

source ./.env-aws
```

Load it:
```bash
source .env
```

Check if all required variables has been set:

```bash
ansible-playbook  mtulio.okd_installer.config \
    -e mode=check-vars \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

#### Install the clients

The binary path of the clients used by installer is `${HOME}/.ansible/okd-installer/bin`*, so the utilities like `openshift-installer` should be in this path.

*it will be more flexible in the future.

To check if the clients used by installer is present, run the client check:

```bash
ansible-playbook mtulio.okd_installer.install_clients
```

To install the clients you can run set the version and run:

```bash
ansible-playbook mtulio.okd_installer.install_clients -e version=4.11.4
```

### Config

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Network Stack

#### Create the network stack

- Create the network stack with default variables

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

- (optional/alternative) Create the network stack with custom variables file (AWS edge example)

```bash
OKD_COLLECTION_PATH=${PWD}/collections/ansible_collections/mtulio/okd_installer
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file=${OKD_COLLECTION_PATH}/playbooks/vars/aws/networks/aws-use1-edge-full.yaml
```

- (optional/alternative) A more customizaded environment variable setting the CIDR block:

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file=${PWD}/vars/networks/aws-use1-single-AZ-peer.yaml \
    -e resource_prefix=singleaz \
    -e cidr_block_16=10.100.0.0/16 -e cidr_prefix_16=10.100
```

### IAM Stack


```bash
ansible-playbook mtulio.okd_installer.stack_iam \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### DNS Stack


```bash
ansible-playbook mtulio.okd_installer.stack_dns \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Load Balancer Stack


```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Compute Stack

- Create the Bootstrap Node

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e role=bootstrap
```

- Create the Control Plane nodes

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e role=controlplane
```

- Create the Compute nodes

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e role=compute
```

### Single Execution (create-all)

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```


#### Finalize

- Approve the certificates (playbook)

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

- Change the intervals to check:

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e certs_max_retries=3 \
    -e cert_wait_interval_sec=10
```

- Approve the certificates (manually)

```bash
approve_certs() {
    export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig
    for i in $(oc get csr --no-headers  | \
                grep -i pending         | \
                awk '{ print $1 }')     ; do \
        echo "> Approving certificate $i"; \
        oc adm certificate approve $i; \
    done
}
while true; do approve_certs; sleep 30; done
```

## Load Balancer for default router (non-integrated platform)


```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file="./vars/${CONFIG_PROVIDER}/loadbalancer-router-default.yaml"
```

## Review the installation

- wait-for install complete

```bash
~/.ansible/okd-installer/bin/openshift-install \
    wait-for install-complete \
    --dir ~/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/ \
    --log-level debug
```

- Review ClusterOperators

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig

oc wait --all --for=condition=Available=True clusteroperators.config.openshift.io --timeout=10m > /dev/null
oc wait --all --for=condition=Progressing=False clusteroperators.config.openshift.io --timeout=10m > /dev/null
oc wait --all --for=condition=Degraded=False clusteroperators.config.openshift.io --timeout=10m > /dev/null

oc get clusteroperators
```

## Alternative Day-2 Operations

### Enable image-registry (non-production clusters)

> [References](https://docs.openshift.com/container-platform/4.6/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html)

```bash
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
```

```bash
ansible-playbook mtulio.okd_installer.create_imageregistry \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

## Destroy cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

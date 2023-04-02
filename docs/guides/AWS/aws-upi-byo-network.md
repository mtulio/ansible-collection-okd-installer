# OKD Install on AWS provider with UPI

!!! warning "TODO / WIP page"
    This page is not completed!


Steps to install OKD/OCP clusters in AWS with user-provisioned infrastructure, with Ansible as IaaC to provision the infrastructure.

## Build-in Use Cases

The use cases described below are re-using playbooks
changing the variables for each goal.

Feel free to look into the Makefile and create your own
customization re-using the playbooks to install k8s/okd/openshift
clusters.

### Prepare the environment

#### Export the environment variables used to create the cluster

Create and export the environment variables (change `CLUSTER_NAME`)
```bash
CLUSTER_NAME="byonet01"
cat <<EOF> ./.env-${CLUSTER_NAME}
export CONFIG_CLUSTER_NAME=${CLUSTER_NAME}
export CONFIG_PROVIDER=aws
export CONFIG_PLATFORM=aws
export CONFIG_BASE_DOMAIN=devcluster.openshift.com
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PLATFORM_SPEC={\'region\':\'us-east-1\'}
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF

source ./.env-${CLUSTER_NAME}
```

### Create or customize the `openshift-install` binary

Check the Guide [Install the `openshift-install` binary](./install-openshift-install.md) if you aren't set or would like to customize the cluster version.

### Config

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Network Stack

#### Create the network stack

- (optional/alternative) A more customizaded environment variable setting the CIDR block:

```bash
CUSTOM_NET_VARS=${PWD}/vars/networks/aws-use1-single-AZ-peer.yaml
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file=${CUSTOM_NET_VARS} \
    -e resource_prefix=singleaz \
    -e cidr_block_16=10.100.0.0/16 -e cidr_prefix_16=10.100
```

Example Local Zone using pre-built network vars for `us-east-1` (or you can specify your own):

```bash
CUSTOM_NET_VARS=${PWD}/vars/networks/aws-use1-localzones.yaml
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file=${CUSTOM_NET_VARS}
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

### Load Balancer Stack (external)

External Load Balancer alternatives when deploying agnostic clusters in AWS provider.

#### NLB (default)

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

#### Approve certificates

The `create_all` already trigger the certificates approval with one default timeout. If the nodes was not yet joined to the cluster (`oc get nodes`) or still have pending certificates (`oc get csr`) due the short delay for approval, you can call it again with longer timeout:

- Approve the certificates (default execution)

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

- Change the intervals to check (example 5 minutes)

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e certs_max_retries=3 \
    -e cert_wait_interval_sec=10
```

## Destroy cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

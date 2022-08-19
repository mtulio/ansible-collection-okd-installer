# Ansible Collection okd_installer

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/release.yml/badge.svg)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/ci.yml/badge.svg?branch=main)
![](https://img.shields.io/ansible/role/59600)


Ansible Collection to install OKD clusters.

The okd_install Ansible Collection was designed to be distributed and easier to implement and deploy infrastructure resources required for OKD Installation, reusing the existing resources (modules and roles) from the Ansible community, implementing only the OKD specific roles, packaging together all necessary dependencies (external Roles).

The infrastructure provisioning was distributed into Stacks, then the Playbooks orchestrate the Stack provisioning by sending the correct embeded/user-provided variables to the Roles, which interacts with Cloud Provider API through oficial Ansible Modules. In general there is one Ansible Role for each stack. The Ansible Roles for Infrastructure stacks are not OKD specific, so it can be reused in other projects, and easily maintained by the community. The 'topologies' for each Roles are defined as variables included on OKD Ansible Collection to satisfy valid cluster topologies.

For example, these components are used on the Network Stack to provision the VPC on AWS:

- Playbook `playbooks/vars/aws/stack_network.yaml` implements the orchestration to create the VPC and required resources (Subnets, Nat and Internet Gateways, security groups, etc), then calls the Ansible Role `cloud_network`
- Var file `playbooks/vars/aws/network.yaml`: Defines the topology of the Network declaring the variable `cloud_networks` (required by role `cloud_network`). Can be replaced when setting `var_file`
- Ansible Role `cloud_network`: Resolve the dependencies and create the resources using community/vendor Ansible Modules, according the `cloud_networks` definition.
- Ansible modules from Community/Vendor: it is distributed as Collection. For AWS the community.aws and amazon.aws are used inside the Ansible Role `cloud_network`

## Content

That collection distribute a set of Ansible Roles and Playbooks used to provision the OKD cluster on specific Platform. Some of resources are managed in an external repository to keep it reusable, easy to maintain, and improve. The external resources are included as Git modules and updated once it needed (is validated).

### Roles

External Roles (included as Git modules/fixed version):

- [cloud_compute](https://github.com/mtulio/ansible-role-cloud-compute): Manage Compute resources
- [cloud_network](https://github.com/mtulio/ansible-role-cloud-compute): Manage networks/VPCs
- [cloud_iam](https://github.com/mtulio/ansible-role-cloud-compute): Manage Cloud identities
- [cloud_load_balancer](https://github.com/mtulio/ansible-role-cloud-compute): Manage Load Balancers
- [cloud_dns](https://github.com/mtulio/ansible-role-cloud-dns): Manage DNS Domains on the Cloud Providers

Internal Roles:

- okd_bootstrap
- okd_cluster_destroy
- okd_install_clients
- okd_installer_config

### Playbooks

Playbooks distributed on this Ansible Collection:

- playbooks/config.yaml
- playbooks/create_node.yaml
- playbooks/destroy_cluster.yaml
- playbooks/install_clients.yaml
- playbooks/ping.yaml
- playbooks/stack_dns.yaml
- playbooks/stack_loadbalancer.yaml
- playbooks/stack_iam.yaml
- playbooks/stack_network.yaml


## Requirements

- Python 3.8 or later

## Setup

Install ansible and dependencies:

```bash
pip install -r hack/requirements.txt
```

Clone the project
```bash
ansible-galaxy collection install mtulio.okd_installer
```

## Usage

### Prepare the environment

#### Export the environment variables used to create the cluster

Create `.env` file or just export it to your session:
```bash
cat <<EOF> .env
export CONFIG_CLUSTER_NAME=mrbans
export CONFIG_PROVIDER=aws
export CONFIG_BASE_DOMAIN=mydomain.openshift.com
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF
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
ansible-playbook mtulio.okd_installer.install_clients -e version=4.11.0
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

- Create the network stack with custom variables file (AWS Example)

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file=${PWD}/vars/networks/aws-usw2.yaml
```

- A more customizaded environment variable setting the CIDR block:

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

- Approve the certificates

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig
for i in $(oc get csr --no-headers  | \
            grep -i pending         | \
            awk '{ print $1 }')     ; do \
    oc adm certificate approve $i; \
done
```

## Load Balancer for default router (non-integrated platform)


```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file="./vars/${CONFIG_PROVIDER}/loadbalancer-router-default.yaml"
```

## Review the installation

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig
oc get clusteroperators
```

## Destroy cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

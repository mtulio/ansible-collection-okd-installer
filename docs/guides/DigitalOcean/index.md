# Guides - DigitalOcean deployment with agnostic installation

Steps to install OKD Clusters in DigitalOcean with agnostic installation.

!!! warning "Development mode"
    This page is under development

## Prerequisites

- Setup ansible workdir

```bash
mkdir okd-installer; cd okd-installer
cat <<EOF > ansible.cfg
[defaults]
inventory = ./inventories
collections_path=./collections
callbacks_enabled=ansible.posix.profile_roles,ansible.posix.profile_tasks
hash_behavior=merge

[inventory]
enable_plugins = yaml, ini

[callback_profile_tasks]
task_output_limit=1000
sort_order=none
EOF
```

- Install the collection okd-installer (dev mode)

```bash
git clone -b added-provider-digitalocean --recursive \
    git@github.com:mtulio/ansible-collection-okd-installer.git \
    collections/ansible_collections/mtulio/okd_installer
```

- Install the dependencies

```bash
pip install -r collections/ansible_collections/mtulio/okd_installer/requirements.txt
ansible-galaxy collection install -r collections/ansible_collections/mtulio/okd_installer/requirements.yml
```

- Create and export the DigitalOcean token

> A read and write [Personal Access Token](https://docs.digitalocean.com/reference/api/) for the API. Make sure you write down the token in a safe place; you’ll need it later on in this tutorial.

```bash
export DO_API_TOKEN=value
```

## Setup the configuration

```bash
CLUSTER_NAME=do-lab02
VARS_FILE=./vars-do-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VARS_FILE}
provider: do
cluster_name: ${CLUSTER_NAME}
config_cluster_region: nyc3

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: splat-do.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.13.0
version: 4.13.0

# Define the OS Image mirror
os_mirror: true
os_mirror_from: stream_artifacts
os_mirror_stream:
  architecture: x86_64
  artifact: openstack
  format: qcow2.gz

os_mirror_to_provider: do
os_mirror_to_do:
  bucket: rhcos-images
  image_type: QCOW2

config_patches:
- rm-capi-machines

EOF
```

- install the clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE
```
- Create the install-config.yaml

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VARS_FILE
```

> The install-config.yaml will be generated in the path `~/.ansible/okd-installer/clusters/$CLUSTER_NAME/install-config.yaml`, modify it as you want.

- Create the manifests

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-manifests -e @$VARS_FILE
```

## Install the cluster

Install stack by stack.

### Network stack

```bash
ansible-playbook mtulio.okd_installer.stack_network -e @$VARS_FILE
```

### IAM Stack

N/A


### DNS Stack

```bash
ansible-playbook mtulio.okd_installer.stack_dns -e @$VARS_FILE
```

#### Load Balancer Stack

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer -e @$VARS_FILE
```

#### Config Commit

This stage allows the user to modify the cluster configurations (manifests),
then generate the ignition files used to create the cluster.

##### Manifest patches (pre-ign)

```bash
ansible-playbook mtulio.okd_installer.config -e mode=patch-manifests -e @$VARS_FILE
```

##### Config generation (ignitions)

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-ignitions -e @$VARS_FILE
```

#### Mirror OS boot image

> TODO for DigitalOcean

```bash
ansible-playbook mtulio.okd_installer.os_mirror -e @$VARS_FILE
```

#### Compute Stack

##### Bootstrap node

- Upload the bootstrap ignition to blob and Create the Bootstrap Instance

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=bootstrap -e @$VARS_FILE
```

##### Control Plane nodes

- Create the Control Plane nodes

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=controlplane -e @$VARS_FILE
```

##### Compute/worker nodes

- Create the Compute nodes

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=compute -e @$VARS_FILE
```

- Approve worker nodes' certificates signing requests (CSR)

```bash
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')

# OR

oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
```

## Review the installation

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${cluster_name}/auth/kubeconfig

oc get nodes
oc get co
```

## Destroy cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```

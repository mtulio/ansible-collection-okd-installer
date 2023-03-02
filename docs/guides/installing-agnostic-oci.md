# Install OKD/OCP on OCI using agnostic method

> This document is under development on https://github.com/mtulio/ansible-collection-okd-installer/pull/26

Install OCP/OKD Cluster on Oracle Cloud Infrastructure using agnostic installation/UPI.

ToC

- Prerequisites
    - Setup Ansible Project
    - Setup OCI Credentials
- OCP/OKD Cluster setup on OCI
    - Install the Clientes
    - Setup the installer artifacts
    - Setup IAM Stack
    - Setup Network Stack
    - Setup DNS Stack
    - Setup Load Balancer Stack
    - Setup Compute Stack
       - Setup Bootstrap
       - Setup Control Plane
       - Setup Compute Pool
- Review the Installation
- Destroy the Clueter

## Prerequisites

### Setup Ansible project

> This steps should be made only when OCI provider is under development - not merged to `main` branch. Then the normal install flow should be used.

- Setup your ansible workdir (optional, you can use the defaults)

```bash
cat <<EOF > ansible.cfg
[defaults]
inventory = ./inventories
collections_path=./collections
callbacks_enabled=ansible.posix.profile_roles,ansible.posix.profile_tasks

[inventory]
enable_plugins = yaml, ini

[callback_profile_tasks]
task_output_limit=1000
sort_order=none
EOF
```

- Create a virtual ennv

```bash
python3.8 -m venv ./.venv-oci
source ./.venv-oci/bin/activate
```

- Donwload requirements files

```
wget https://raw.githubusercontent.com/mtulio/ansible-collection-okd-installer/main/requirements.yml
wget https://raw.githubusercontent.com/mtulio/ansible-collection-okd-installer/main/requirements.txt
```

- Update with OCI requirements

```bash
cat <<EOF >> requirements.txt

# Oracle Cloud Infrastructure
oci
EOF

cat <<EOF >> requirements.yml

# Oracle Cloud Infrastructure Ansible Collections
# https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.11.0/installation/index.html
- name: oracle.oci
  version: '>=4.11.0,<4.12.0'
EOF
```

- Install ansible and dependencies

```bash
pip install -r requirements.txt
```

- Install the Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

- Get the latest (under development) okd-installer for OCI

> https://github.com/mtulio/ansible-collection-okd-installer/pull/26

```bash
git clone -b feat-add-provider-oci --recursive \
    git@github.com:mtulio/ansible-collection-okd-installer.git \
    collections/ansible_collections/mtulio/okd_installer
```

- Check if the collection is present


```bash
$ ansible-galaxy collection list |egrep "(okd_installer|^oracle)"
mtulio.okd_installer 0.0.0-latest
oracle.oci           4.11.0 
```

### Setup OCI credentials

- See [API Key Authentication](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.11.0/guides/authentication.html#api-key-authentication):
- See https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two


Make sure your credentials have been set correctly on the file `~/.oci/config` and you can use the OCI ansible collection:

- Get the User ID from the documentation

```bash
export oci_user_id=$(grep ^user ~/.oci/config | awk -F '=' '{print$2}')
```

- Retrieve facts from the user

```bash
ansible localhost \
    -m oracle.oci.oci_identity_user_facts \
    -a user_id=${oci_user_id}
```

You must be able to collect the user information.

## OCP Cluster Setup on OCI

### Generate the vars file

```bash
cat <<EOF > ~/.oci/env
OCI_COMPARTMENT_ID="<CHANGE_ME:ocid1.compartment.oc1.UUID>"
EOF
source ~/.oci/env

cat <<EOF > ./vars-oci-ha.yaml
provider: oci
cluster_name: mrb
config_cluster_region: us-sanjose-1

oci_compartment_id: ${OCI_COMPARTMENT_ID}

config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: ${HOME}/.openshift/pull-secret-latest.json

cluster_profile: ha
destroy_bootstrap: no

controlplane_instance: VM.Standard3.Flex
controlplane_instance_spec:
  cpu_count: 8
  memory_gb: 16

compute_instance: VM.Standard3.Flex
compute_instance_spec:
  cpu_count: 8
  memory_gb: 16

# Define the OS Image
#> extract from stream file
# https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202212081411-0/aarch64/rhcos-412.86.202212081411-0-openstack.aarch64.qcow2.gz
# $ jq -r '.architectures["x86_64"].artifacts.openstack.formats["qcow2.gz"].disk.location' ~/.ansible/okd-installer/clusters/ocp-oci/coreos-stream.json`
custom_image_id: rhcos-412.86.202212081411-0-openstack.aarch64.qcow2.gz
EOF
```

### Install the clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e version=4.12.0
```

### Create the Installer Configuration

Create the installation configuration:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e @./vars-oci-ha.yaml
```

### Create the Network Stack

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e @./vars-oci-ha.yaml
```

### IAM Stack

N/A

### DNS Stack

```bash
ansible-playbook mtulio.okd_installer.stack_dns \
    -e @./vars-oci-ha.yaml
```

### Load Balancer Stack

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e @./vars-oci-ha.yaml
```

### Compute Stack


#### Bootstrap

- Mirror image (Ansible Role+Playbook Not implemented)

> TODO: config to mirror from openstack image to OCI 

> Currently the image is download manually, and added to the OCI Console as a image.


Steps to mirror using OCI Console:

- Get the artifact URL from stream-json
- Create Bucket for images, if not exits
- Upload the image qcow2.gz
- Get the signed URL for the image object
- Create an image from signed URL
- Get the image ID, and set the global var `custom_image_id`

> `$ jq -r '.architectures["x86_64"].artifacts.openstack.formats["qcow2.gz"].disk.location' ~/.ansible/okd-installer/clusters/ocp-oci/coreos-stream.json`

Proposal to automate:

> Agnostic instalations frequently requires to upload to  the provider. why no create one internal Role to do it?! Steps: Download from stream URL, upload to Provider's image, Use it.

```bash
os_mirror: yes
os_mirror_src: stream
os_mirror_stream:
  architecture: x86_64
  platform: openstack
  format: qcow2.gz

os_mirror_dest_provider: oci
os_mirror_dest_oci:
  compartment_id: 
  bucket:
```

- Upload the bootstrap ignition to blob and Create the Bootstrap Instance

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e node_role=bootstrap \
    -e @./vars-oci-ha.yaml
```

- Create the Control Plane nodes

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e node_role=controlplane \
    -e @./vars-oci-ha.yaml
```

- Create the Compute nodes

> TODO: create instance Pool

> TODO: Approve certificates (bash loop or use existing playbook)

```
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')
```

## Review the cluster

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${cluster_name}/auth/kubeconfig

oc get nodes
oc get co
```

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
hash_behavior=merge

[inventory]
enable_plugins = yaml, ini

[callback_profile_tasks]
task_output_limit=1000
sort_order=none
EOF
```

- Create a virtual ennv

```bash
python3.9 -m venv ./.venv-oci
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
git clone -b feat-added-provider-oci --recursive \
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
# Compartment that the cluster will be installed
OCI_COMPARTMENT_ID="<CHANGE_ME:ocid1.compartment.oc1.UUID>"

# Compartment that the DNS Zone is created (based domain)
# Only RR will be added
OCI_COMPARTMENT_ID_DNS="<CHANGE_ME:ocid1.compartment.oc1.UUID>"

# Compartment that the OS Image will be created
OCI_COMPARTMENT_ID_IMAGE="<CHANGE_ME:ocid1.compartment.oc1.UUID>"
EOF
source ~/.oci/env

cat <<EOF > ~/.openshift/env
export OCP_CUSTOM_RELEASE="docker.io/mtulio/ocp-release:latest"

OCP_RELEASE_413="quay.io/openshift-release-dev/ocp-release:4.13.0-ec.4-x86_64"
EOF
source ~/.openshift/env

CLUSTER_NAME=oci-cr3cmo
cat <<EOF > ./vars-oci-ha_${CLUSTER_NAME}.yaml
provider: oci
cluster_name: ${CLUSTER_NAME}
config_cluster_region: us-sanjose-1

#TODO: create compartment validations
#TODO: allow create compartment from a parent
oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

#config_cluster_version: 4.13.0-ec.3-x86_64
version: 4.13.0-ec.3
config_installer_environment:
  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "${OCP_CUSTOM_RELEASE}"

controlplane_instance: VM.Standard3.Flex
controlplane_instance_spec:
  cpu_count: 8
  memory_gb: 16

compute_instance: VM.Standard3.Flex
compute_instance_spec:
  cpu_count: 8
  memory_gb: 16

# Define the OS Image mirror
# custom_image_id: rhcos-412.86.202212081411-0-openstack.x86_64

os_mirror: yes
os_mirror_from: stream_artifacts
os_mirror_stream:
  architecture: x86_64
  artifact: openstack
  format: qcow2.gz
  # TO test:
  #artifact: aws
  #format: vmdk.gz

os_mirror_to_provider: oci
os_mirror_to_oci:
  compartment_id: ${OCI_COMPARTMENT_ID_IMAGE}
  bucket: rhcos-images
  image_type: QCOW2
  #image_type: VMDK


## Apply patches to installer manifests (WIP)

# TODO: we must keep the OCI CCM manifests patch more generic

config_patches:
- rm-capi-machines
#- platform-external-kubelet # PROBLEM hangin kubelete (network)
#- platform-external-kcmo
- deploy-oci-ccm
- yaml_patch # working for OCI, but need to know the path
#- line_regex_patch # ideal, but not working as expected

cfg_patch_yaml_patch_specs:
    ## patch infra object to create External provider
  - manifest: /manifests/cluster-infrastructure-02-config.yml
    patch: '{"spec":{"platformSpec":{"type":"External","external":{"platformName":"oci"}}},"status":{"platform":"External","platformStatus":{"type":"External","external":{}}}}'

    ## OCI : Change the namespace from downloaded assets
  #- manifest: /manifests/oci-cloud-controller-manager-02.yaml
  #  patch: '{"metadata":{"namespace":"oci-cloud-controller-manager"}}'

cfg_patch_line_regex_patch_specs:
  - manifest: /manifests/oci-cloud-controller-manager-01-rbac.yaml
    #search_string: 'namespace: kube-system'
    regexp: '^(.*)(namespace\\: kube-system)$'
    #line: 'namespace: oci-cloud-controller-manager'
    line: '\\1namespace: oci-cloud-controller-manager'

  - manifest:  /manifests/oci-cloud-controller-manager-02.yaml
    regexp: '^(.*)(namespace\\: kube-system)$'
    line: '\\1namespace: oci-cloud-controller-manager'
EOF


```

### Install the clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @./vars-oci-ha.yaml
```

### Create the Installer Configuration

Create the installation configuration:


```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e @./vars-oci-ha.yaml
```

### Mirror the image

- Mirror image

> Example: `$ jq -r '.architectures["x86_64"].artifacts.openstack.formats["qcow2.gz"].disk.location' ~/.ansible/okd-installer/clusters/ocp-oci/coreos-stream.json`

```bash
ansible-playbook mtulio.okd_installer.os_mirror -e @./vars-oci-ha.yaml
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

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e node_role=compute \
    -e @./vars-oci-ha.yaml
```

> TODO: create instance Pool

> TODO: Approve certificates (bash loop or use existing playbook)

```bash
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')
```

### Create all

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60 \
    -e @./vars-oci-ha.yaml
```

> TO DO: measure total time

## Review the cluster

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${cluster_name}/auth/kubeconfig

oc get nodes
oc get co
```

## OPCT setup

- Create the OPCT [dedicated] node

> https://redhat-openshift-ecosystem.github.io/provider-certification-tool/user/#option-a-command-line

```bash
# Create OPCT node
ansible-playbook mtulio.okd_installer.create_node \
    -e node_role=opct \
    -e @./vars-oci-ha.yaml
```

- OPCT dedicated node setup

```bash

# Set the OPCT requirements (registry, labels, wait-for COs stable)
ansible-playbook ../opct/hack/opct-runner/opct-run-tool-preflight.yaml -e cluster_name=oci -D

oc label node opct-01.priv.ocp.oraclevcn.com node-role.kubernetes.io/tests=""
oc adm taint node opct-01.priv.ocp.oraclevcn.com node-role.kubernetes.io/tests="":NoSchedule

```

- OPCT regular

```bash
# Run OPCT
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 run -w

# Get the results and explore it
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 retrieve
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 results *.tar.gz
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 report *.tar.gz
```

- OPCT upgrade mode

```bash
# from a cluster 4.12.1, run upgrade conformance to 4.13
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 run -w \
  --mode=upgrade \
  --upgrade-to-image=$(oc adm release info 4.13.0-ec.2 -o jsonpath={.image})

# Get the results and explore it
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 retrieve
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 results *.tar.gz
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 report *.tar.gz
```

## Generate custom image

```

```

## Destroy

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @./vars-oci-ha.yaml
```

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

CLUSTER_NAME=oci-t13
VAR_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VAR_FILE}
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
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub;cat ~/.ssh/openshift-dev.pub)"
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
#- mc-kubelet-env-workaround # PROBLEM hangin kubelet (network)
- mc-kubelet-providerid
#- platform-external-kcmo
- deploy-oci-ccm
#- deploy-oci-csi
- yaml_patch # working for OCI, but need to know the path
#- line_regex_patch # ideal, but not working as expected

cfg_patch_yaml_patch_specs:
    ## patch infra object to create External provider
  - manifest: /manifests/cluster-infrastructure-02-config.yml
    patch: '{"spec":{"platformSpec":{"type":"External","external":{"platformName":"oci"}}},"status":{"platform":"External","platformStatus":{"type":"External","external":{}}}}'

cfg_patch_line_regex_patch_specs:
  - manifest: /manifests/oci-cloud-controller-manager-01-rbac.yaml
    #search_string: 'namespace: kube-system'
    regexp: '^(.*)(namespace\\: kube-system)$'
    #line: 'namespace: oci-cloud-controller-manager'
    line: '\\1namespace: oci-cloud-controller-manager'

  - manifest:  /manifests/oci-cloud-controller-manager-02.yaml
    regexp: '^(.*)(namespace\\: kube-system)$'
    line: '\\1namespace: oci-cloud-controller-manager'

cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);

EOF

```

### Install the clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VAR_FILE
```

### Create the Installer Configuration

Create the installation configuration:


```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VAR_FILE
```

The rendered install-config.yaml will be available on the following path:

- `~/.ansible/okd-installer/clusters/$CLUSTER_NAME/install-config.yaml`

If you want to skip this part, place your own install-config.yaml on the same
path and go to the next step.

### Create the Installer manifests

Create the installation configuration:

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-manifests -e @$VAR_FILE
```

The manifests will be rendered and saved on the install directory:

- `~/.ansible/okd-installer/clusters/$CLUSTER_NAME/`

If you want to skip that part, with your own manifests, you must be able to run
the `openshift-install create manifests` under the install dir, and the file
`manifests/cluster-config.yaml` is created correctly.

The infrastructure manifest also must exist on path: `manifests/cluster-infrastructure-02-config.yml`.


**After this stage, the file `$install_dir/cluster_state.json` will be created and populated with the stack results.**

### IAM Stack

N/A

> TODO: create Compartment validations

### Create the Network Stack

```bash
ansible-playbook mtulio.okd_installer.stack_network -e @$VAR_FILE
```

### DNS Stack

```bash
ansible-playbook mtulio.okd_installer.stack_dns -e @$VAR_FILE
```

### Load Balancer Stack

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer -e @$VAR_FILE
```

### Config Commit

This stage allows the user to modify the cluster configurations (manifests),
then generate the ignition files used to create the cluster.

#### Manifest patches (pre-ign)

In this step the playbooks will apply any patchs to the manifests,
according to the vars file `config_patches`.

The `config_patches` are predefined tasks that will run to reach specific goals.

If you wouldn't like to apply patches, leave the empty value `config_patches: []`.

If you would like to apply patches manually, you can do it changing the manifests
on the install dir. Default install dir path: `~/.ansible/okd-installer/clusters/${cluster_name}/*`

```bash
ansible-playbook mtulio.okd_installer.config -e mode=patch-manifests -e @$VAR_FILE
```

#### Config generation (ignitions)

> TODO/WIP

This steps should be the last before the configuration be 'commited':

- `create ignitions` when using `openshift-install` as config provider
- `` when using `assisted installer` as a config provider

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-ignitions -e @$VAR_FILE
```

<!-- #### Ignition patchs (Post)

> TODO? there's no used case to patch the ingnition files, and it's not recommended. So keeping this section hiden to the document for future review. -->

### Mirror OS boot image

- Download image from URL provided by openshift-install coreos-stream

> Example: `$ jq -r '.architectures["x86_64"].artifacts.openstack.formats["qcow2.gz"].disk.location' ~/.ansible/okd-installer/clusters/ocp-oci/coreos-stream.json`

```bash
ansible-playbook mtulio.okd_installer.os_mirror -e @$VAR_FILE
```

### Compute Stack

#### Bootstrap node

- Upload the bootstrap ignition to blob and Create the Bootstrap Instance

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=bootstrap -e @$VAR_FILE
```

#### Control Plane nodes

- Create the Control Plane nodes

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=controlplane -e @$VAR_FILE
```

#### Compute/worker nodes

- Create the Compute nodes

```bash
ansible-playbook mtulio.okd_installer.create_node -e node_role=compute -e @$VAR_FILE
```

> TODO: create instance Pool

- Approve worker nodes certificates signing requests (CSR)

```bash
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')
```

### Create all

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60 \
    -e @$VAR_FILE
```

## Review the cluster

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${cluster_name}/auth/kubeconfig

oc get nodes
oc get co
```

## Destroy

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VAR_FILE
```

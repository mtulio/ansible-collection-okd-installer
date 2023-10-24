# Install OKD/OCP on OCI using an agnostic method

> This document is under development on https://github.com/mtulio/ansible-collection-okd-installer/pull/26

Install OCP/OKD Cluster on Oracle Cloud Infrastructure using agnostic installation/UPI.

- Prerequisites
- Installing OCP
    - Install the Clientes
    - Option 1 - Install quickly
    - Option 2 - Install step-by-stack
        - Create the Install config
        - Create the manifests
        - Setup IAM Stack
        - Setup Network Stack
        - Setup DNS Stack
        - Setup Load Balancer Stack
        - Patch the manifests
        - Create the ignitions
        - Setup Compute Stack
            - Setup Bootstrap
            - Setup Control Plane nodes
            - Setup Compute nodes
            - Check/Approve the certificates
- Review the Installation
- Destroy the Cluster

## Prerequisites

- okd-installer Collection with [OCI dependencies installed](./prerequisites.md):
- Compartments used to launch the cluster created and exported to variable `${OCI_COMPARTMENT_ID}`
- DNS Zone place the DNS zone and exported to variable `${OCI_COMPARTMENT_ID_DNS}`
- Compartment used to store the RHCOS image exported to variable `${OCI_COMPARTMENT_ID_IMAGE}`

Example:

```bash
cat <<EOF > ~/.oci/env
# Compartment that the cluster will be installed
OCI_COMPARTMENT_ID="<CHANGE_ME:ocid1.compartment.oc1.UUID>"

# Compartment that the DNS Zone is created (based domain)
OCI_COMPARTMENT_ID_DNS="<CHANGE_ME:ocid1.compartment.oc1.UUID>"

# Compartment that the OS Image will be created
OCI_COMPARTMENT_ID_IMAGE="<CHANGE_ME:ocid1.compartment.oc1.UUID>"
EOF
source ~/.oci/env
```

- If you are using python virtual env, like me ;D, set the interpreter path:

```bash
ANSIBLE_PYTHON_INTERPRETER=${VENV_PATH}/$VIRTUAL_ENV/bin/python3
```

## Installing OpenShift/OKD

### Create the vars file

```bash
CLUSTER_NAME=oci-n414rc6
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

ANSIBLE_PYTHON_INTERPRETER=${VENV_PATH}/$VIRTUAL_ENV/bin/python3

cat <<EOF > ${VARS_FILE}
provider: oci
cluster_name: ${CLUSTER_NAME}

config_cluster_region: us-ashburn-1
config_base_domain: us-ashburn-1.splat-oci.devcluster.openshift.com

oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}

cluster_profile: ha
destroy_bootstrap: no

config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.14.0-rc.6
version: 4.14.0-rc.6

os_mirror: yes
os_mirror_from: stream_artifacts
os_mirror_stream:
  architecture: x86_64
  artifact: openstack
  format: qcow2.gz

os_mirror_to_provider: oci
os_mirror_to_oci:
  compartment_id: ${OCI_COMPARTMENT_ID_IMAGE}
  bucket: rhcos-images
  image_type: QCOW2

config_patches:
- rm-capi-machines
EOF
```

### Install the clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE
```

### Installing option 1: quickly install

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60 \
    -e @$VARS_FILE
```

### Installing option 2: step-by-step

#### Create the Installer Configuration

Create the installation configuration:


```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VARS_FILE
```

The rendered install-config.yaml will be available on the following path:

- `~/.ansible/okd-installer/clusters/$CLUSTER_NAME/install-config.yaml`

If you want to skip this part, place your own install-config.yaml on the same
path and go to the next step.

#### Create the Installer manifests

Create the installation configuration:

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-manifests -e @$VARS_FILE
```

The manifests will be rendered and saved on the install directory:

- `~/.ansible/okd-installer/clusters/$CLUSTER_NAME/`

If you want to skip that part, with your manifests, you must be able to run
the `openshift-install create manifests` under the install directory, and the file
`manifests/cluster-config.yaml` is created correctly.

The infrastructure manifest also must exist on the path: `manifests/cluster-infrastructure-02-config.yml`.


**After this stage, the file `$install_dir/cluster_state.json` will be created and populated with the stack results.**

#### IAM Stack

N/A

> TODO: create Compartment validations

#### Create the Network Stack

```bash
ansible-playbook mtulio.okd_installer.stack_network -e @$VARS_FILE
```

#### DNS Stack

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

In this step, the playbooks will apply any patches to the manifests,
according to the vars file `config_patches`.

The `config_patches` are predefined tasks that will run to reach specific goals.

If you wouldn't like to apply patches, leave the empty value `config_patches: []`.

If you would like to apply patches manually, you can do it by changing the manifests
on the install dir. Default install dir path: `~/.ansible/okd-installer/clusters/${cluster_name}/*`

```bash
ansible-playbook mtulio.okd_installer.config -e mode=patch-manifests -e @$VARS_FILE
```

##### Config generation (ignitions)

These steps should be the last before the configuration be 'committed':

- `create ignitions` when using `openshift-install` as the config provider

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-ignitions -e @$VARS_FILE
```

#### Mirror OS boot image

- Download the image from the URL provided by openshift-install coreos-stream

> Example: `$ jq -r '.architectures["x86_64"].artifacts.openstack.formats["qcow2.gz"].disk.location' ~/.ansible/okd-installer/clusters/ocp-oci/coreos-stream.json`

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

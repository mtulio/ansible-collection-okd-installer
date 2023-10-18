## Install a OCP cluster with ARM64 Arch on Oracle Cloud Infrastructure (OCI) with CCM

Install an OCP cluster in OCI with Platform External as an option and OCI Cloud Controler Manager.

## Prerequisites

- okd-installer Collection with [OCI dependencies installed](./oci-prerequisites.md):
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

## Setup with Platform External type and CCM

Create the vars file for okd-installer collection:

```bash
# MCO patch without revendor (w/o disabling FG)
CLUSTER_NAME=oci-e414rc2arm1usash1
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VARS_FILE}
provider: oci
cluster_name: ${CLUSTER_NAME}
config_cluster_region: us-ashburn-1

cluster_profile: ha
destroy_bootstrap: no

#config_base_domain: splat-oci.devcluster.openshift.com
config_base_domain: us-ashburn-1.splat-oci.devcluster.openshift.com

config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.14.0-rc.2
version: 4.14.0-rc.2

config_platform: external
config_platform_spec: '{"platformName":"oci"}'

oci_ccm_namespace: oci-cloud-controller-manager
oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}

# Available manifest paches (runs after 'create manifest' stage)
config_patches:
- rm-capi-machines
- mc_varlibetcd
- mc-kubelet-providerid
- deploy-oci-ccm
#- deploy-oci-csi

# MachineConfig to set the Kubelet environment. Will use this script to discover the ProviderID
cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);

# spread nodes between "AZs"
oci_availability_domains:
- gzqB:US-ASHBURN-AD-1
- gzqB:US-ASHBURN-AD-2
- gzqB:US-ASHBURN-AD-3

oci_fault_domains:
- FAULT-DOMAIN-1
- FAULT-DOMAIN-2
- FAULT-DOMAIN-3

# OCI config for ARM64
config_default_architecture: arm64
compute_shape: "VM.Standard.A1.Flex"
controlplane_shape: "VM.Standard.A1.Flex"
bootstrap_instance: "VM.Standard.A1.Flex"

# Define the OS Image mirror
os_mirror: yes
os_mirror_from: stream_artifacts
os_mirror_stream:
  architecture: aarch64
  artifact: openstack
  format: qcow2.gz

os_mirror_to_provider: oci
os_mirror_to_oci:
  compartment_id: ${OCI_COMPARTMENT_ID_IMAGE}
  bucket: rhcos-images
  image_type: QCOW2
  # not supported yet, must be added for arm64
  # https://oci-ansible-collection.readthedocs.io/en/latest/collections/oracle/oci/oci_compute_image_shape_compatibility_entry_module.html#ansible-collections-oracle-oci-oci-compute-image-shape-compatibility-entry-module
  compatibility_shapes:
  - name: VM.Standard.A1.Flex
    memory_constraints:
      min_in_gbs: 4
      max_in_gbs: 128
    ocpu_constraints:
      min: 2
      max: 32
EOF
```

## Install the cluster

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e cert_max_retries=30 \
    -e cert_wait_interval_sec=60 \
    -e @$VARS_FILE
```

### Approve certificates

Export `KUBECONFIG`:

```bash
export KUBECONFIG=$HOME/.ansible/okd-installer/clusters/${CLUSTER_NAME}/auth/kubeconfig
```

Check and Approve the certificates:
```bash
oc get csr \
  -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' \
  | xargs oc adm certificate approve
```

Check if the nodes joined to the cluster:

```bash
oc get nodes
```

## Testing

Setup the test environment (internal registry, labeling and taint worker node, etc):

```bash
test_node=$(oc get nodes -l node-role.kubernetes.io/worker='' -o jsonpath='{.items[0].metadata.name}')
oc label node $test_node node-role.kubernetes.io/tests=""
oc adm taint node $test_node node-role.kubernetes.io/tests="":NoSchedule
```

Run the tests:

```bash
./opct run -w &&\
  ./opct retrieve &&\
  ./opct report *.tar.gz --save-to /tmp/results --server-skip
```

## Destroy the cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```
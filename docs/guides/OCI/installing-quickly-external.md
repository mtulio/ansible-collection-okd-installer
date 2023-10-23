## Install a cluster on Oracle Cloud Infrastructure (OCI) with CCM

Install an OCP cluster in OCI with Platform External as an option and OCI Cloud Controler Manager.

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

## Setup with Platform External type and CCM

Create the vars file for okd-installer collection:

```bash
# MCO patch without revendor (w/o disabling FG)
CLUSTER_NAME=oci-e414rc2ad3v1
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

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

config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.14.0-rc.2
version: 4.14.0-rc.2

# Platform External setup
config_platform: external
config_platform_spec: '{"platformName":"oci"}'

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

oci_ccm_namespace: oci-cloud-controller-manager

# Define the OS Image mirror
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

# Experimental: increase the boot volume performance
# controlplane_source_details:
#   source_type: image
#   boot_volume_size_in_gbs: 1200
#   boot_volume_vpus_per_gb: 120

# Mount control plane as a second volume
# cfg_patch_mc_varlibetcd:
#   device_path: /dev/sdb

# spread nodes between "AZs"
oci_availability_domains:
- gzqB:US-ASHBURN-AD-1
- gzqB:US-ASHBURN-AD-2
- gzqB:US-ASHBURN-AD-3

oci_fault_domains:
- FAULT-DOMAIN-1
- FAULT-DOMAIN-2
- FAULT-DOMAIN-3
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
ansible-playbook opct-runner/opct-run-tool-preflight.yaml -e @$VARS_FILE
```

Run the tests:

> TMP note: remove the `-serial`

```bash
~/opct/bin/opct-devel run -w --plugins-image openshift-tests-provider-cert:devel-serial &&\
  ~/opct/bin/opct-devel retrieve &&\
  ~/opct/bin/opct-devel report *.tar.gz --save-to /tmp/results --server-skip
```

## Destroy the cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```
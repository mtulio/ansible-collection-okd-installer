## Install a cluster on Oracle Cloud Infrastructure (OCI) with CCM

Install an OCP cluster in OCI with Platform External as an option and OCI Cloud Controler Manager.

## Requirements

- okd-installer Collection with [OCI dependencies installed](./oci-prerequisites.md):
- Child Compartment created in Oracle Cloud Console to install the cluster, place the DNS zone and compute images

## OCP Cluster Setup on OCI

### Create the vars file

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


CLUSTER_NAME=oci-ext03
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VARS_FILE}
provider: oci
cluster_name: ${CLUSTER_NAME}
config_cluster_region: us-sanjose-1

oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub; cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.13.0-rc.0
version: 4.13.0-rc.0

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

EOF


# Platform External setup only
cat <<EOF >> ${VARS_FILE}

# Platform External specifics (preview release with minimal changes)
config_installer_environment:
  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "quay.io/mrbraga/ocp-release:4.13.0-rc.0-x86_64_platexternal-kcmo-mco-3cmo"

# Available manifest paches (runs after 'create manifest' stage)
config_patches:
- rm-capi-machines
- mc-kubelet-providerid
- deploy-oci-ccm
- deploy-oci-csi
- yaml_patch

# YAML Patches
cfg_patch_yaml_patch_specs:
  ## patch infra object to create External provider
  - manifest: /manifests/cluster-infrastructure-02-config.yml
    patch: '{"spec":{"platformSpec":{"type":"External","external":{"platformName":"oci"}}},"status":{"platform":"External","platformStatus":{"type":"External","external":{}}}}'

# MachineConfig to set the Kubelet environment. Will use this script to discover the ProviderID
cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);

# Choose CCM deployment parameters
## Use patched manifests for OCP
oci_ccm_namespace: oci-cloud-controller-manager
## Use default manifests from github https://github.com/oracle/oci-cloud-controller-manager#deployment
## Note: that method is failing when copying the manifests 'as-is' in OCP. Need more investigation:
# oci_ccm_namespace: kube-system
# oci_ccm_version: v1.25.0

EOF
```

### Install the cluster

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60 \
    -e @$VARS_FILE
```

## Destroy the cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```
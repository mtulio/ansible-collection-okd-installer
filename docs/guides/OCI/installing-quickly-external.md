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

# MCO patch without revendor (w/o disabling FG)
CLUSTER_NAME=oci-e414rc0
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
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

config_cluster_version: 4.14.0-rc.0
version: 4.14.0-rc.0

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

config_platform: external
config_platform_spec: '{"platformName":"oci"}'

# Available manifest paches (runs after 'create manifest' stage)
config_patches:
- rm-capi-machines
- mc-kubelet-providerid
- deploy-oci-ccm
- deploy-oci-csi

# MachineConfig to set the Kubelet environment. Will use this script to discover the ProviderID
cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);

oci_ccm_namespace: oci-cloud-controller-manager

EOF
```

### Install the cluster

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e cert_max_retries=30 \
    -e cert_wait_interval_sec=60 \
    -e @$VARS_FILE
```

### Destroy the cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```

### Steps by playbook

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-manifests -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_network -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_dns -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_loadbalancer -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=patch-manifests -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-ignitions -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.os_mirror -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=bootstrap -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=controlplane -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=compute -e @$VARS_FILE
export KUBECONFIG=
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')

ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```

## Examples

### Installing 4.14 with CCM

- OCP 4.14-nightly-patched_CMO + Platform External + OCI + CSI
```bash
CLUSTER_NAME=oci-ext108
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VARS_FILE}
provider: oci
cluster_name: ${CLUSTER_NAME}
config_cluster_region: us-sanjose-1

release_image: quay.io/mrbraga/ocp-release
release_version: 4.14.0-0.nightly-2023-07-05-071214

config_platform: external
config_platform_spec: '{"platformName":"oci"}'

config_installer_environment:
  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "quay.io/mrbraga/ocp-release:4.14.0-0.nightly-2023-07-05-071214"

config_featureset: TechPreviewNoUpgrade
config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"

cluster_profile: ha
destroy_bootstrap: no

oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}
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

# Available manifest paches (runs after 'create manifest' stage)
config_patches:
- rm-capi-machines
- mc-kubelet-providerid
- deploy-oci-ccm
- deploy-oci-csi

# MachineConfig to set the Kubelet environment. Will use this script to discover the ProviderID
cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);
EOF
```


- OKD SCOS 4.14-nightly-patched_CMO + Platform External + OCI + CSI
```bash
CLUSTER_NAME=oci-ext107
VARS_FILE=./vars-oci-ha_${CLUSTER_NAME}.yaml

cat <<EOF > ${VARS_FILE}
provider: oci
cluster_name: ${CLUSTER_NAME}
config_cluster_region: us-sanjose-1

release_image: quay.io/mrbraga/ocp-release
release_version: 4.14.0-0.nightly-2023-07-05-071214

config_platform: external
config_platform_spec: '{"platformName":"oci"}'

config_installer_environment:
  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "quay.io/mrbraga/ocp-release:4.14.0-0.nightly-2023-07-05-071214"

config_featureset: TechPreviewNoUpgrade
config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-okd-fake.json"

cluster_profile: ha
destroy_bootstrap: no

oci_compartment_id: ${OCI_COMPARTMENT_ID}
oci_compartment_id_dns: ${OCI_COMPARTMENT_ID_DNS}
oci_compartment_id_image: ${OCI_COMPARTMENT_ID_IMAGE}
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

# Available manifest paches (runs after 'create manifest' stage)
config_patches:
- rm-capi-machines
- mc-kubelet-providerid
- deploy-oci-ccm
- deploy-oci-csi

# MachineConfig to set the Kubelet environment. Will use this script to discover the ProviderID
cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);
EOF
```
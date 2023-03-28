## Install a cluster on OCI with CCM

## Requirements

- Credentials
- Client installed

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

OCP_RELEASE_413="quay.io/mrbraga/ocp-release:4.13.0-rc.0-x86_64_platexternal-kcmo-mco-3cmo"
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

config_cluster_version: 4.13.0-rc.0
version: 4.13.0-rc.0
config_installer_environment:
  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "$OCP_RELEASE_413"

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

## Apply patches to installer manifests (WIP)
# TODO: we must keep the OCI CCM manifests patch more generic

config_patches:
- rm-capi-machines
- mc-kubelet-providerid
- deploy-oci-ccm
- deploy-oci-csi
- yaml_patch

cfg_patch_yaml_patch_specs:
    ## patch infra object to create External provider
  - manifest: /manifests/cluster-infrastructure-02-config.yml
    patch: '{"spec":{"platformSpec":{"type":"External","external":{"platformName":"oci"}}},"status":{"platform":"External","platformStatus":{"type":"External","external":{}}}}'

cfg_patch_kubelet_providerid_script: |
    PROVIDERID=\$(curl -H "Authorization: Bearer Oracle" -sL http://169.254.169.254/opc/v2/instance/ | jq -r .id);

EOF
```

### Install the cluster

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60 \
    -e @$VAR_FILE
```

## Destroy

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VAR_FILE
```

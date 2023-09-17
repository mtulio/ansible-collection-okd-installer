# Installing in OCI with build-in examples

## Export variables

```bash
export OKD_CONFIG_BASE_DOMAIN="<CHANGE_ME:base_domain_value>"
export OCI_COMPARTMENT_ID="<CHANGE_ME:compartment_id>"
export OCI_COMPARTMENT_ID_DNS="<CHANGE_ME:compartment_id>"
export OCI_COMPARTMENT_ID_IMAGE="<CHANGE_ME:compartment_id>"
export OS_MIRROR_IMAGE_BUCKET_NAME="rhcos-images"
```

### Default vars


## Installing


### Installing a cluster on OCI with Platform Agnostic/None

> TODO

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/ha-platform-none.yaml
```

### Installing a cluster on OCI with Platform Agnostic/None with CSI Driver

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/ha-platform-none-csi.yaml
```

### Installing a cluster on OCI with Platform External

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/ha-platform-external.yaml
```

### Installing a cluster on OCI with Platform External with CCM

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/ha-platform-external-ccm.yaml
```

### Installing a cluster on OCI with Platform External with CCM and CSI Driver

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/ha-platform-external-ccm-csi.yaml
```

### Installing a cluster on OCI with Platform External with CSI Driver

> TODO: OCI CSI Driver can be installed in Platform None with manual changes

<!-- ### Installing a cluster on OCI with Platform None and Assisted Installer as Config Provider

```bash
ansible-playbook examples/create-cluster.yaml \
    -e cluster_name=name \
    -e @./examples/vars/common.yaml \
    -e @./examples/vars/oci/common.yaml \
    -e @./examples/vars/oci/AI-ha-platform-none.yaml
``` -->

### Destroy a cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e cluster_name=name
```
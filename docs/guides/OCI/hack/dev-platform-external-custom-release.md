# Platform External - creating a custom release to support it on 4.13

This guide describe how to create a custom OCP release image with minimal changes to enable Platform `External` to be considered 'external' on the `library-go` - `IsCloudProviderExternal()`, signalizing the Kubelet (MCO) and Kube Controller Manager (KCMO) flag `--cloud-provider` be external, waiting for an external CCM be deployed on install time (in this case [OCI CCM](https://github.com/oracle/oci-cloud-controller-manager))

This is part of a PoC to enable Platform External to install CCM on install time. All the work has been mapped on the [Enhancement Proposal 1353](https://github.com/openshift/enhancements/pull/1353).

## Update the API

### API

> The minimal changes on API have been created on 4.13. It's not required for this PoC.

References:

- https://github.com/openshift/api/pull/1301
- https://github.com/openshift/api/pull/1409

### library-go

- Clone the Library-go

- Make the changes: https://github.com/openshift/library-go/compare/release-4.13...mtulio:library-go:release-4.13-platexternal?expand=1#diff-478af36e9fb994fc80d37b7d2f6ae207c67d8c43b94f98f6ae3e420808958ba9R40-R41

- Push to your account


## Rebuilding KCMO

Steps to propagate the library-go change to kube-controller-manager-operator.

- Clone the repo https://github.com/openshift/cluster-kube-controller-manager-operator

- Update the go.mod to use your version of library-go https://github.com/openshift/cluster-kube-controller-manager-operator/compare/release-4.13...mtulio:cluster-kube-controller-manager-operator:release-4.13-platexternal?expand=1

`go.mod`
```
replace github.com/openshift/library-go => github.com/mtulio/library-go v0.0.0-20230313023417-78e409222bff
```

- upload your custom changes (optional)

```bash
$ git remote -v
mtulio  git@github.com:mtulio/cluster-kube-controller-manager-operator.git (fetch)
mtulio  git@github.com:mtulio/cluster-kube-controller-manager-operator.git (push)
origin  git@github.com:openshift/cluster-kube-controller-manager-operator.git (fetch)
$ git push --set-upstream mtulio release-4.13-platexternal  -f
```

- Build a custom image


```bash
QUAY_USER=mrbraga
REPO_NAME=cluster-kube-controller-manager-operator

podman build \
    --authfile ${PULL_SECRET} \
    -f Dockerfile.rhel7 \
    -t quay.io/${QUAY_USER}/${REPO_NAME}:latest \
    && podman push quay.io/${QUAY_USER}/${REPO_NAME}:latest

TS=$(date +%Y%m%d%H%M)
podman tag quay.io/${QUAY_USER}/${REPO_NAME}:latest \
    "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}" && \
    podman push "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}"
```

## Building MCO

Steps to propagate the library-go change to machine-config-operator.

- Clone the repo https://github.com/openshift/machine-config-operator

- Update the go.mod to use your version of library-go

`go.mod`
```
replace github.com/openshift/library-go => github.com/mtulio/library-go v0.0.0-20230313023417-78e409222bff
```

- Build a custom image

```shell
QUAY_USER=mrbraga
REPO_NAME=machine-config-operator

podman build -f Dockerfile.rhel7 \
    -t quay.io/${QUAY_USER}/${REPO_NAME}:latest && \
    podman push quay.io/${QUAY_USER}/${REPO_NAME}:latest

TS=$(date +%Y%m%d%H%M)
podman tag quay.io/${QUAY_USER}/${REPO_NAME}:latest \
    "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}" && \
    podman push "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}"
```

## Building CCCMO

Steps to propagate the library-go change to cluster-cloud-controller-manager-operator.

- Clone the repo https://github.com/mtulio/cluster-cloud-controller-manager-operator

- Update the go.mod to use your version of library-go

- Build a custom image

```bash
QUAY_USER=mrbraga
REPO_NAME=cluster-cloud-controller-manager-operator

podman build \
    --authfile ${PULL_SECRET} \
    -f Dockerfile \
    -t quay.io/${QUAY_USER}/${REPO_NAME}:latest \
    && podman push quay.io/${QUAY_USER}/${REPO_NAME}:latest

TS=$(date +%Y%m%d%H%M)
podman tag quay.io/${QUAY_USER}/${REPO_NAME}:latest \
    "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}" && \
    podman push "quay.io/${QUAY_USER}/${REPO_NAME}:${TS}"
```

## Create a new release

- Choose the base image on https://openshift-release.apps.ci.l2s4.p1.openshiftapps.com/

- Run the command

```bash
VERSION_BASE="4.13.0-rc.0-x86_64"
OCP_RELEASE_BASE="quay.io/openshift-release-dev/ocp-release:${VERSION_BASE}"
CUSTOM_IMAGE_NAMESPACE="quay.io/${QUAY_USER}"
NEW_RELEASE_IMAGE="docker.io/mtulio/ocp-release"

$(which time) -v oc adm release new -n origin \
  --server https://api.ci.openshift.org \
  -a ${PULL_SECRET} \
  --from-release ${OCP_RELEASE_BASE} \
  --to-image "${NEW_RELEASE_IMAGE}:latest" \
  machine-config-operator=${CUSTOM_IMAGE_NAMESPACE}/machine-config-operator:latest \
  cluster-kube-controller-manager-operator=${CUSTOM_IMAGE_NAMESPACE}/cluster-kube-controller-manager-operator:latest \
  cluster-cloud-controller-manager-operator=${CUSTOM_IMAGE_NAMESPACE}/cluster-cloud-controller-manager-operator:latest
```

- Mirror it creating custom labels to identify the customization and base image

```bash
podman pull "${NEW_RELEASE_IMAGE}:latest"

podman tag "${NEW_RELEASE_IMAGE}:latest" \
    "${CUSTOM_IMAGE_NAMESPACE}/ocp-release:latest" && \
    podman push "${CUSTOM_IMAGE_NAMESPACE}/ocp-release:latest"
podman tag "${NEW_RELEASE_IMAGE}:latest" \
    "${CUSTOM_IMAGE_NAMESPACE}/ocp-release:${VERSION_BASE}_platexternal-kcmo-mco-3cmo" && \
    podman push "${CUSTOM_IMAGE_NAMESPACE}/ocp-release:${VERSION_BASE}_platexternal-kcmo-mco-3cmo"
```

- Check if the release image `${NEW_RELEASE_IMAGE}:latest` was created

- Use it

```bash
OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "quay.io/mrbraga/ocp-release:4.13.0-rc.0-x86_64_platexternal-kcmo-mco-3cmo" \
    openshift-install create cluster --dir my-install-dir/
```

## Usage custom release in this collection

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
# OKD Install Guide on AWS provider with platform agnostic

Steps to install OpenShift cluster on AWS with Platform Agnostic installation (`platform:None`).

Table of Contents:

- [Setup the environment](#setup)
    - [Create and export config variables](#setup-vars)
    - [Create the install config](#setup-config)
- [Create the cluster](#create-cluster)
- [Cluster Review (optional)](#review)
    - [Approve the node certificates](#review-approve-csr)
    - [Wait for install complete](#review-wait-for-complete)
    - [Review Cluster Operators](#review-clusteroperators)
    - [Day-2 Operation: Enable image-registry](#review-day2-enable-registry)
    - [Create Load Balancer for default router](#review-create-ingress-lb)
- [Destroy cluster](#destroy-cluster)


## Setup the environment <a name="setup"></a>

### Create and export config variables <a name="setup-vars"></a>

Create and export the environment file:

- `platform.none: {}`
```bash
CLUSTER_NAME="aws-22122701"
cat <<EOF> ./.env-${CLUSTER_NAME}
export CONFIG_CLUSTER_NAME=${CLUSTER_NAME}
export CONFIG_PROVIDER=aws
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PLATFORM=none
export CONFIG_BASE_DOMAIN=devcluster.openshift.com
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF

source ./.env-${CLUSTER_NAME}
```

Create the env var file (NEW):

```bash
cat <<EOF > ./vars-aws-ha.yaml
provider: aws
cluster_name: aws-ext7
config_cluster_region: us-east-1

config_base_domain: devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: ${HOME}/.openshift/pull-secret-latest.json

cluster_profile: ha
destroy_bootstrap: no

config_cluster_version: 4.13.0-ec.4-x86_64
version: 4.13.0-ec.4
config_installer_environment:
    OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE: "quay.io/openshift-release-dev/ocp-release:4.13.0-ec.4-x86_64"

config_patches:
- rm-capi-machines
#- platform-external-kubelet # PROBLEM hangin kubelete (network)
- platform-external-kcmo
- deploy-oci-ccm
- yaml_patch
- line_regex_patch

cfg_patch_yaml_patch_specs:
    ## patch infra object to create External provider
#  - manifest: /manifests/cluster-infrastructure-02-config.yml
#    patch: '{"spec":{"platformSpec":{"type":"External","external":{"platformName":"aws"}}},"status":{"platform":"External","platformStatus":{"type":"External","external":{}}}}'

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

Check if all required variables has been set:

```bash
ansible-playbook  mtulio.okd_installer.config \
    -e mode=check-vars \
    -e @./vars-aws-ha.yaml
```

### Create or customize the `openshift-install` binary

Check the Guide [Install the `openshift-install` binary](./install-openshift-install.md) if you aren't set or would like to customize the cluster version.

### Create the install config <a name="setup-config"></a>

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e @./vars-aws-ha.yaml
```

## Create the cluster <a name="create-cluster"></a>

The okd-installer Collection provides one single playbook to create the cluster based on the environment variables and install-config previously created on the last sections. If you would like to review stack-by-stack and add customizations, you can check the ["AWS UPI Guide"](./aws-upi.md)

Call the playbook to create the cluster:

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e @./vars-aws-ha.yaml \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60
```

## Cluster Review (optional) <a name="review"></a>

### Approve the node certificates <a name="review-approve-csr"></a>

The `create_all` already trigger the certificates approval with one default timeout. If the nodes was not yet joined to the cluster (`oc get nodes`) or still have pending certificates (`oc get csr`) due the short delay for approval, you can call it again with longer timeout, for example 5 minutes:

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e certs_max_retries=3 \
    -e cert_wait_interval_sec=60
```

<!-- - Approve the certificates (manually)

```bash
approve_certs() {
    export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig
    for i in $(oc get csr --no-headers  | \
                grep -i pending         | \
                awk '{ print $1 }')     ; do \
        echo "> Approving certificate $i"; \
        oc adm certificate approve $i; \
    done
}
while true; do approve_certs; sleep 30; done
``` -->

### Wait for install complete <a name="review-wait-for-complete"></a>

```bash
~/.ansible/okd-installer/bin/openshift-install \
    wait-for install-complete \
    --dir ~/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/ \
    --log-level debug
```

### Review Cluster Operators <a name="review-clusteroperators"></a>

```bash
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig

oc wait --all --for=condition=Available=True clusteroperators.config.openshift.io --timeout=10m > /dev/null
oc wait --all --for=condition=Progressing=False clusteroperators.config.openshift.io --timeout=10m > /dev/null
oc wait --all --for=condition=Degraded=False clusteroperators.config.openshift.io --timeout=10m > /dev/null

oc get clusteroperators
```

### Day-2 Operation: Enable image-registry <a name="review-day2-enable-registry"></a>

> NOTE: steps used in non-production clusters

> [References](https://docs.openshift.com/container-platform/4.6/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html)

```bash
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
```

<!-- ```bash
ansible-playbook mtulio.okd_installer.create_imageregistry \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
``` -->

### Create Load Balancer for default router <a name="review-create-ingress-lb"></a>

This steps is optional as the `create_all` playbook already trigger it.

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e var_file="./vars/${CONFIG_PROVIDER}/loadbalancer-router-default.yaml"
```


## Destroy cluster <a name="destroy-cluster"></a>

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e @./vars-aws-ha.yaml
```

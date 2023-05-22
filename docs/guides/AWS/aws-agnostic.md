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

Create and export the environments:

- When deploying **OpenShift**:

```bash
# Release controller for each distribution:
# OKD: https://amd64.origin.releases.ci.openshift.org/
# OCP: https://openshift-release.apps.ci.l2s4.p1.openshiftapps.com/
DISTRIBUTION="ocp"
RELEASE_REPO="quay.io/openshift-release-dev/ocp-release"
RELEASE_VERSION="4.13.0-x86_64"
PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"
```

- When deploying **OKD with FCOS**:

```bash
DISTRIBUTION="okd"
RELEASE_REPO=quay.io/openshift/okd
RELEASE_VERSION=4.12.0-0.okd-2023-04-16-041331
PULL_SECRET_FILE="{{ playbook_dir }}/../tests/config/pull-secret-okd-fake.json"
```

- When deploying **OKD with SCOS**:

```bash
DISTRIBUTION="okd"
RELEASE_REPO=quay.io/okd/scos-release
RELEASE_VERSION=4.13.0-0.okd-scos-2023-05-04-192252
PULL_SECRET_FILE="{{ playbook_dir }}/../tests/config/pull-secret-okd-fake.json"
```

Create the Ansible var files:


```bash
CLUSTER_NAME="aws-none05"
BASE_DOMAIN="devcluster.openshift.com"
SSH_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)"

VARS_FILE="./vars-${CLUSTER_NAME}.yaml"
cat <<EOF> $VARS_FILE

cluster_name: ${CLUSTER_NAME}
config_base_domain: ${BASE_DOMAIN}

distro_default: $DISTRIBUTION
release_image: $RELEASE_REPO
release_version: $RELEASE_VERSION
#release_image_version_arch: "quay.io/openshift-release-dev/ocp-release:4.13.0-x86_64"

provider: aws
config_provider: aws
config_platform: none
cluster_profile: ha
config_cluster_region: us-east-1

config_ssh_key: "${SSH_PUB_KEY}"
config_pull_secret_file: "${PULL_SECRET_FILE}"
EOF
```

Check if all required variables has been set:

```bash
ansible-playbook  mtulio.okd_installer.config -e mode=check-vars -e @$VARS_FILE
```

### Create or customize the `openshift-install` binary

Check the Guide [Install the `openshift-install` binary](./install-openshift-install.md) if you aren't set or would like to customize the cluster version.

```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE
```

### Create the install config <a name="setup-config"></a>

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VARS_FILE
```

## Create the cluster <a name="create-cluster"></a>

The okd-installer Collection provides one single playbook to create the cluster based on the environment variables and install-config previously created on the last sections. If you would like to review stack-by-stack and add customizations, you can check the ["AWS UPI Guide"](./aws-upi.md)

Call the playbook to create the cluster:

```bash
ansible-playbook mtulio.okd_installer.create_all -e @$VARS_FILE
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

## Destroy cluster <a name="destroy-cluster"></a>

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

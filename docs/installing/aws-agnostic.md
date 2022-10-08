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

Check if all required variables has been set:

```bash
ansible-playbook  mtulio.okd_installer.config \
    -e mode=check-vars \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Create or customize the `openshift-install` binary

Check the Guide [Install the `openshift-install` binary](./install-openshift-install.md) if you aren't set or would like to customize the cluster version.

### Create the install config <a name="setup-config"></a>

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

## Create the cluster <a name="create-cluster"></a>

The okd-installer Collection provides one single playbook to create the cluster based on the environment variables and install-config previously created on the last sections. If you would like to review stack-by-stack and add customizations, you can check the ["AWS UPI Guide"](./aws-upi.md)

Call the playbook to create the cluster:

```bash
ansible-playbook mtulio.okd_installer.create_all \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
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
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

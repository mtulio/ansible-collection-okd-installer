# AWS Single Node Openshift

Install a single node OpenShift.

Steps:
- Generate the SNO ignitions
- Create the Stacks: Network, IAM, DNS, LB
- Create the Compute with ignition

## Pre-req

```bash
CLUSTER_NAME="sno-aws"
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

## Client

## Config


```bash
cat <<EOF> ./vars-sno.yaml
provider: aws

cluster_name: ${CLUSTER_NAME}
config_compute_replicas: 0
config_controlplane_replicas: 1
config_bootstrapinplace_disk: /dev/nvme0n1

config_topology: sno
cluster_topology: sno
topology_network: sno
topology_iam: sno
topology_dns: sno
topology_lb: sno
topology_compute: sno
EOF
```


```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e @./vars-sno.yaml
```

## Network Stack

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e @./vars-sno.yaml
```

### IAM Stack


```bash
ansible-playbook mtulio.okd_installer.stack_iam \
    -e @./vars-sno.yaml
```

### DNS Stack

```bash
ansible-playbook mtulio.okd_installer.stack_dns \
    -e @./vars-sno.yaml
```

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e @./vars-sno.yaml
```

### Compute Stack

- Create the Bootstrap Node

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e @./vars-sno.yaml \
    -e node_role=controlplane
```


### Destroy

??

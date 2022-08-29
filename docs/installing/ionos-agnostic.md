# OKD Install on IONOS provider with platform agnostic

> State: WIP

## Setup the environment

### Install

- Checke if python version is greater than 3.8

```bash
$ python -V
Python 3.8.12
```

<!-- - Create the python virtual environment (optional if you would like to isolate the project setup)

```bash
$ python3.8 -m venv ~/.venvs/okd-installer-latest
$ ~/.venvs/okd-installer-latest/bin/activate
$ python -V
Python 3.8.12
``` -->

- Install Ansible

```bash
pip install -U pip ansible>=4.1
```

- Install the Collection [okd-installer](https://galaxy.ansible.com/mtulio/okd_installer)

```bash
pip install jmespath
ansible-galaxy collection install mtulio.okd_installer
```

- Install [IONOS Ansible Collection](https://docs.ionos.com/ansible/)

```bash
pip install ionoscloud
ansible-galaxy collection install ionoscloudsdk.ionoscloud
```

### Export the environment variables

- IONOS credentials

```bash
export IONOS_USERNAME=myuser
export IONOS_PASSWORD=mypass
```

Create `.env` file or just export it to your session:

```bash
cat <<EOF> .env
export IONOS_USERNAME=myuser
export IONOS_PASSWORD=mypass

export CONFIG_CLUSTER_NAME=okd-ionos
export CONFIG_PROVIDER=ionos
export CONFIG_BASE_DOMAIN=mydomain.openshift.com
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF
```

Load it:
```bash
source .env
```

## Install the OKD Stacks

### Config

```bash
ansible-playbook  mtulio.okd_installer.config \
    -e mode=check-vars \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Network

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### IAM

Skip

### DNS

> ToDo: not supported in IONOS

### Load Balancer Stack

```bash
ansible-playbook mtulio.okd_installer.stack_loadbalancer \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

### Compute Stack

- Create the Bootstrap Node

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e role=bootstrap
```

```bash
ansible-playbook mtulio.okd_installer.create_node \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e role=master
```


# okd-installer - Getting Started

> WIP

> TODO Content for Getting started

- Simple Install
- Simple Setup
- Simple Create Cluster
- Simple Test
- References more Installing Guides

## See Next

- [AWS User-Provisioned Installation](./installing/aws-upi.md)
- [AWS with Agnostic Installation](./installing/aws-agnostic.md)
- [DigitalOcean with Agnostic Installation](./installing/digitalOcean-agnostic.md)

---
---

> TODO review and distribute items below to specific docs:

## Install Ansible Collection `okd-installer`

### Install and configure Ansible

- Install Ansible
```bash
pip3 instlal requirements.txt
```

- Create the configuration

```bash
cat << EOF > ./ansible.cfg
 $ cat ansible.cfg 
[defaults]
collections_path=./collections
EOF
```

### Install the Collection

```bash
git clone git@github.com:mtulio/ansible-collection-okd-installer.git collections/ansible_collections/mtulio/okd_installer/
```

## Install the OpenShift Clients <a name="install-clients"></a>

The binary path of the clients used by installer is `${HOME}/.ansible/okd-installer/bin`, so the utilities like `openshift-installer` and `oc` should be present in this path.

To check if the clients used by installer is present, run the client check:

```bash
ansible-playbook mtulio.okd_installer.install_clients
```

To install you should have one valid pull secret file path exported to the environment variable `CONFIG_PULL_SECRET_FILE`. Example:

```bash
export CONFIG_PULL_SECRET_FILE=/home/mtulio/.openshift/pull-secret-latest.json
```

To install the clients you can run set the version and run:

```bash
ansible-playbook mtulio.okd_installer.install_clients -e version=4.11.4
```

## Example of configuration <a name="install-config"></a>

This is one example how to create the configuration.

### Export the environment variables

> The environment variables is the only steps supported at this moment. We will add more examples in the future to create your own playbook setting the your custom variables.


#### Generate the Configuration

To generate the install config, you must set variables (defined above) and the cluster_name:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

The install-config.yaml will be available on the path: `${HOME}/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/install-config.yaml`.

# Install OKD/OCP on OCI using agnostic method

Install OCP/OKD Cluster on Oracle Cloud Infrastructure using agnostic installation/UPI.

## Prerequisites


### Setup Ansible project

- Setup your ansible workdir (optional, you can use the defaults)

```bash
cat <<EOF > ansible.cfg
[defaults]
inventory = ./inventories
collections_path=./collections
callbacks_enabled=ansible.posix.profile_roles,ansible.posix.profile_tasks

[inventory]
enable_plugins = yaml, ini

[callback_profile_tasks]
task_output_limit=1000
sort_order=none
EOF
```

- Create a virtual ennv

```bash
python3.8 -m venv ./.venv-oci
source ./.venv-oci/bin/activate
```

- Donwload requirements files

```
wget https://raw.githubusercontent.com/mtulio/ansible-collection-okd-installer/main/requirements.yml
wget https://raw.githubusercontent.com/mtulio/ansible-collection-okd-installer/main/requirements.txt
```

- Update with OCI requirements

```
cat <<EOF >> requirements.txt

# Oracle Cloud Infrastructure
oci
EOF

cat <<EOF >> requirements.yml

# Oracle Cloud Infrastructure Ansible Collections
# https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.11.0/installation/index.html
- name: oracle.oci
  version: '>=4.11.0,<4.12.0'
EOF
```

- Install ansible and dependencies

```
pip install -r requirements.txt
```

- Install the collections

```
ansible-galaxy collection install -r requirements.yml
```

- Get the latest (under development) okd-installer for OCI

```
git clone -b feat-add-provider-oci --recursive \
    git@github.com:mtulio/ansible-collection-okd-installer.git \
    collections/ansible_collections/mtulio/okd_installer
```

- Check if the collection is present


```
$ ansible-galaxy collection list |egrep "(okd_installer|^oracle)"
mtulio.okd_installer 0.0.0-latest
oracle.oci           4.11.0 
```

### Setup OCI credentials

- See [API Key Authentication](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.11.0/guides/authentication.html#api-key-authentication):
- See https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two


Make sure your credentials have been set correctly on the file `~/.oci/config` and you can use the OCI ansible collection:

- Get the User ID from the documentation

```bash
export oci_user_id=$(grep ^user ~/.oci/config | awk -F '=' '{print$2}')
```

- Retrieve facts from the user

```bash
ansible localhost \
    -m oracle.oci.oci_identity_user_facts \
    -a user_id=${oci_user_id}
```

You must be able to collect the user information.

## okd-installer

### Generate the vars file

```bash
cat <<EOF > ~/.oci/env
OCI_COMPARTMENT_ID="<CHANGE_ME:ocid1.compartment.oc1.UUID>"
EOF

source ~/.oci/env
cat <<EOF > ./vars-oci-ha.yaml
provider: oci
cluster_name: ocp-oci
config_cluster_region: us-sanjose-1

oci_compartment_id: ${}

config_base_domain: splat-oci.devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: ${HOME}/.openshift/pull-secret-latest.json

cluster_profile: ha
destroy_bootstrap: no

controlplane_instance: VM.Standard3.Flex
controlplane_instance_spec:
  cpu_count: 8
  memory_gb: 16

compute_instance: VM.Standard3.Flex
compute_instance_spec:
  cpu_count: 8
  memory_gb: 16

# https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202212081411-0/aarch64/rhcos-412.86.202212081411-0-openstack.aarch64.qcow2.gz
custom_image_id: rhcos-412.86.202212081411-0-openstack.aarch64.qcow2.gz
EOF
```

### Install the OpenShift clients

```bash
ansible-playbook mtulio.okd_installer.install_clients -e version=4.12.0
```

### Create the Installer Configuration

Create the installation configuration:

```bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e @./vars-oci-ha.yaml
```

### Create the Network Stack

```bash
ansible-playbook mtulio.okd_installer.stack_network \
    -e @./vars-oci-ha.yaml
```


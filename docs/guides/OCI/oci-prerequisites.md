# OCI PoC - Prerequisites

The steps described on this document can be changed from the final version.

The goal is to quickly setup the PoC environment installing all the dependencies to deploy a cluster in Oracle Cloud Infrastructure - official Collection `oracle.oci`, setup identities to use the CLI/SDK, etc.

### Setup Ansible project

> This steps should be made only when OCI provider is under development in the branch `feat-added-provider-oci`.

- Setup the ansible workdir (optional, you can use the defaults except the `collections_path`)

```bash
cat <<EOF > ansible.cfg
[defaults]
inventory = ./inventories
collections_path=./collections
callbacks_enabled=ansible.posix.profile_roles,ansible.posix.profile_tasks
hash_behavior=merge

[inventory]
enable_plugins = yaml, ini

[callback_profile_tasks]
task_output_limit=1000
sort_order=none
EOF
```

- Create a virtual env

> Tested in Python 3.9 and 3.10

```bash
python3.9 -m venv ./.oci
source ./.oci/bin/activate
```

- Get the latest (under development) okd-installer collection with OCI modules:

> https://github.com/mtulio/ansible-collection-okd-installer/pull/26

```bash
git clone -b feat-added-provider-oci --recursive \
    git@github.com:mtulio/ansible-collection-okd-installer.git \
    collections/ansible_collections/mtulio/okd_installer
```

- Install the dependencies:

```bash
pip install -r collections/ansible_collections/mtulio/okd_installer/requirements.txt
ansible-galaxy collection install -r collections/ansible_collections/mtulio/okd_installer/requirements.yml
```

- Check if the collection is present


```bash
$ ansible-galaxy collection list |egrep "(okd_installer|^oracle)"
mtulio.okd_installer 0.0.0-latest
oracle.oci           4.23.0
```

### Setup OCI credentials

- See [API Key Authentication](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.11.0/guides/authentication.html#api-key-authentication):
- See https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two


Make sure your credentials have been set correctly on the file `~/.oci/config` and you can use the OCI ansible collection:

- Get the User ID from the documentation

> you may need to adapt if there are more than one profile

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

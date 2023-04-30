# okd-installer - Getting Started

!!! warning "TODO / WIP page"
    This page is not completed!

Overview of the stack delivered by Ansible Collectio okd-installer:

- okd-installer's specific Ansible Playbook and Roles
- generic cloud provisioning Ansible Roles


<div class="mxgraph" style="max-width:100%;border:1px solid transparent;" data-mxgraph="{&quot;highlight&quot;:&quot;#0000ff&quot;,&quot;nav&quot;:true,&quot;resize&quot;:true,&quot;toolbar&quot;:&quot;zoom layers tags lightbox&quot;,&quot;xml&quot;:&quot;&lt;mxfile host=\&quot;app.diagrams.net\&quot; modified=\&quot;2023-04-02T04:32:31.821Z\&quot; agent=\&quot;5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36\&quot; etag=\&quot;L41tIIaEN30AF7vzDrX3\&quot; version=\&quot;16.2.4\&quot; type=\&quot;google\&quot;&gt;&lt;diagram name=\&quot;project-overview1\&quot; id=\&quot;vKpH1MVvlxqbtfG_vI3H\&quot;&gt;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&lt;/diagram&gt;&lt;/mxfile&gt;&quot;}"></div>
<script type="text/javascript" src="https://viewer.diagrams.net/js/viewer-static.min.js"></script>

> TODO Content for Getting started


Guides:

- Quick Install
- Quick Setup
- Quick Create Cluster
- Quick Test
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

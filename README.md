# Ansible Collection okd_installer

[![Project Status: WIP – Initial development is in progress, it is not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![](https://github.com/mtulio/ansible-collection-okd-installer/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mtulio/ansible-collection-okd-installer/actions/workflows/ci.yml)
[![](https://img.shields.io/ansible/collection/1867)](https://galaxy.ansible.com/mtulio/okd_installer)

Ansible Collection to install OKD clusters.

The okd_install Ansible Collection was designed to be distributed and easier to implement and deploy infrastructure resources required for OKD Installation, reusing the existing resources (modules and roles) from the Ansible community, implementing only the OKD specific roles, packaging together all necessary dependencies (external Roles).

The infrastructure provisioning is distributed into 'Stacks'. The Playbooks orchestrate each Stack provisioning by sending the correct embeded/user-provided variables to the Ansible Roles, which interacts with Cloud Provider API through oficial Ansible Modules. In general there is one Ansible Role for each stack. The Ansible Roles for Infrastructure Stacks are not OKD specific, so it can be reused in other projects like BYO Cloud IaC, making it maintained by Ansible community builders. The 'topologies' for each Ansbile Role are defined as variables included on OKD Ansible Collection to satisfy valid cluster topologies.

For example, these components are used on the Network Stack to provision the VPC on AWS:

- Ansible Playbook `playbooks/stack_network.yaml` implements the orchestration to create the VPC and required resources (Subnets, Nat and Internet Gateways, security groups, etc), then calls the Ansible Role `cloud_network`
- Var file `playbooks/vars/aws/network.yaml`: Defines the topology of the Network declaring the variable `cloud_networks` (required by role `cloud_network`). Can be replaced when setting `var_file`
- Ansible Role `cloud_network`: Resolve the dependencies and create the resources using community/vendor Ansible Modules, according the `cloud_networks` variable. The [Ansible Role `cloud_network`](https://github.com/mtulio/ansible-role-cloud-network) is an external role.
- Ansible Modules from Community/Vendor: it is distributed as Collection. For AWS the community.aws and amazon.aws are used inside the Ansible Role `cloud_network`

## Content

That collection distribute a set of Ansible Roles and Playbooks used to provision the OKD cluster on specific Platform. Some of resources are managed in an external repository to keep it reusable, easy to maintain, and improve. The external resources are included as Git modules and updated once it needed (is validated).

### Roles

External Roles (included as Git modules/fixed version):

- [cloud_compute](https://github.com/mtulio/ansible-role-cloud-compute): Manage Compute resources
- [cloud_network](https://github.com/mtulio/ansible-role-cloud-network): Manage networks/VPCs
- [cloud_iam](https://github.com/mtulio/ansible-role-cloud-iam): Manage Cloud identities
- [cloud_load_balancer](https://github.com/mtulio/ansible-role-cloud-load-balancer): Manage Load Balancers
- [cloud_dns](https://github.com/mtulio/ansible-role-cloud-dns): Manage DNS Domains on the Cloud Providers

Internal Roles:

- [bootstrap](https://github.com/mtulio/ansible-collection-okd-installer/tree/main/roles/bootstrap): Setup bootstrap dependencies, like uploading ignition to a blob storage to be used on bootstrap's node user-data.
- [okd_cluster_destroy](https://github.com/mtulio/ansible-collection-okd-installer/tree/main/roles/okd_cluster_destroy): Destroy the cluster for a given provider
- [clients](https://github.com/mtulio/ansible-collection-okd-installer/tree/main/roles/clients): Install openshift clients used by the playbooks. Some tools installed is: openshift-install, oc, ccoctl, etc
- [config](https://github.com/mtulio/ansible-collection-okd-installer/tree/main/roles/config): Generate Install config and ignition files based on the desired cluster setup
- [csr_approver](https://github.com/mtulio/ansible-collection-okd-installer/tree/main/roles/csr_approver): Approve the CSRs from compute nodes (a.k.a: workers)

### Playbooks

Playbooks distributed on this Ansible Collection:

- playbooks/install_clients.yaml
- playbooks/config.yaml
- playbooks/stack_network.yaml
- playbooks/stack_iam.yaml
- playbooks/stack_dns.yaml
- playbooks/stack_loadbalancer.yaml
- playbooks/create_node.yaml
- playbooks/create_node_all.yaml
- playbooks/create_all.yaml
- playbooks/approve_certs.yaml
- playbooks/destroy_cluster.yaml
- playbooks/destroy_bootstrap.yaml
- playbooks/ping.yaml

## Supported Cloud Platforms

Supported Cloud Platforms* and installation types:

| Platform/Install Type | IPI | UPI | Agnostic** |
| -- | -- | -- | -- |
| AWS | No | Yes | Yes |
| Azure | No | No | No |
| GCP | No | No | No |
| AlibabaCloud | No | No | No |
<!-- | DigitalOcean | N/A | N/A | Init |
| Vultr | N/A | N/A | No |
| Ionos | N/A | N/A | No | -->


*To okd-installer Collection support a cloud provider, the stacks should be defined and the collection should be tested. The focus on okd-installer collection will provide flexibility to customize infrastructure in OKD supported and non-supported providers. If you would a fully automated installation you can use the installer (`openshift-install`) directly.

**Agnostic installation means that OKD there's no native integration with the Platform (config `platform.None: {}`). `None` means there is playbooks to create the infrastrucutre resources to install OCP/OKD on the Cloud Provider, but no native integration with the platform will be available on the OKD, which means every controller to interact with the Cloud Resource should be added separatelly.

We will add a guide to describe how to integrate a new provider by defining the playbooks to create the resource/stacks, calling it from okd-installer Collection. The basic requirement is to have the Ansible Modules publicaly available, some examples: [AWS](https://docs.ansible.com/ansible/latest/collections/community/aws/index.html), [GCP](https://docs.ansible.com/ansible/latest/collections/community/google/index.html), [Azure](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/index.html), [IBM Cloud](https://github.com/IBM-Cloud/ansible-collection-ibm) [VMWare](https://docs.ansible.com/ansible/latest/collections/vmware/vmware_rest/index.html#plugins-in-vmware-vmware-rest), [Digital Ocean](https://docs.ansible.com/ansible/latest/collections/community/digitalocean/index.html), [Vultr](https://docs.ansible.com/ansible/latest/collections/vultr/cloud/index.html#plugins-in-vultr-cloud), [HetznerCloud](https://docs.ansible.com/ansible/latest/collections/hetzner/hcloud/index.html#plugins-in-hetzner-hcloud), [AlibabaCloud](https://docs.ansible.com/ansible/latest/scenario_guides/guide_alicloud.html), [HuaweiCloud](https://github.com/huaweicloud/huaweicloud-ansible-modules), [OracleCloud](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/4.6.0/) etc.

## Usage

Quick start:

- Install the okd-installer Collection

> Navigate to the [Collection page](https://galaxy.ansible.com/mtulio/okd_installer) to change the version.

~~~
ansible-galaxy collection install mtulio.okd_installer:=0.1.0-beta4
~~~

- Install the OKD/OCP clients: oc and openshift-install

~~~
ansible-playbook mtulio.okd_installer.install_clients -e version=4.11.4
~~~

- Export the env vars to create a OKD cluster in AWS with agnostic integraion (platform=none)

~~~bash
CLUSTER_NAME="aws-none"
cat <<EOF> ./.env-${CLUSTER_NAME}
export CONFIG_CLUSTER_NAME=${CLUSTER_NAME}
export CONFIG_PROVIDER=aws
export CONFIG_CLUSTER_REGION=us-east-1
export CONFIG_PLATFORM=none
export CONFIG_BASE_DOMAIN=devcluster.example.com
export CONFIG_PULL_SECRET_FILE=${HOME}/.openshift/pull-secret-latest.json
export CONFIG_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
EOF

source ./.env-${CLUSTER_NAME}
~~~

- Generate the Install Config

~~~bash
ansible-playbook mtulio.okd_installer.config \
    -e mode=create \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
~~~

- Create a Cluster - installing all the Stacks (Network, IAM, DNS, Compute ...)

> All the resource/stacks will be created with Ansible, instead of `openshift-install` utility

~~~bash
ansible-playbook mtulio.okd_installer.create_all \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e certs_max_retries=20 \
    -e cert_wait_interval_sec=60
~~~

- Check the Cluster installation

~~~bash
~/.ansible/okd-installer/bin/openshift-install \
    wait-for install-complete \
    --dir ~/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/ \
    --log-level debug
~~~

- Explore your cluster

~~~bash
export KUBECONFIG=~/.ansible/okd-installer/clusters/${CONFIG_CLUSTER_NAME}/auth/kubeconfig

oc get clusteroperators

# Or use the CLI downloaed by the okd-installer
~/.ansible/okd-installer/bin/oc get co
~~~

- Delete a Cluster

~~~bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
~~~

#### Read more the documentation

The Guides and Documentation are being created under the directoy [docs](./docs/README.md).

## Contribute!

You can see the value and would like to contribute?! We are open to hearing from you.

See some items we need immediate contributions:

- CI improvement: implement more tests; mock provider API; improve linter items
- Documentation: Deployment documentation; Usage documentation
- Examples: Implement example playbooks

If you would like to contribute to any other item not listed above, feel free to open an issue or a Pull request. =]

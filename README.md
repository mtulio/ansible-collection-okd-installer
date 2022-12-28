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
- [cloud_network](https://github.com/mtulio/ansible-role-cloud-compute): Manage networks/VPCs
- [cloud_iam](https://github.com/mtulio/ansible-role-cloud-compute): Manage Cloud identities
- [cloud_load_balancer](https://github.com/mtulio/ansible-role-cloud-compute): Manage Load Balancers
- [cloud_dns](https://github.com/mtulio/ansible-role-cloud-dns): Manage DNS Domains on the Cloud Providers

Internal Roles:

- okd_bootstrap
- okd_cluster_destroy
- okd_install_clients
- okd_installer_config

### Playbooks

Playbooks distributed on this Ansible Collection:

- playbooks/config.yaml
- playbooks/create_node.yaml
- playbooks/destroy_cluster.yaml
- playbooks/install_clients.yaml
- playbooks/ping.yaml
- playbooks/stack_dns.yaml
- playbooks/stack_loadbalancer.yaml
- playbooks/stack_iam.yaml
- playbooks/stack_network.yaml

## Supported Cloud Platforms

Supported Cloud Platforms* and installation types:

| Platform/Install Type | IPI | UPI | Agnostic* |
| -- | -- | -- | -- |
| AWS | No | Yes | Yes |
| Azure | No | No | No |
| GCP | No | No | No |
| AlibabaCloud | No | No | No |
| DigitalOcean | N/A | N/A | WIP |
| Vultr | N/A | N/A | No |
| Ionos | N/A | N/A | No |


*Agnostic installation means that OKD there's no native integration with the Platform.
**None means there is support to install OKD on this platform, but no native integration will be available on the OKD, which means every controller to interact with the Cloud Resource should be added separatelly.

## Contribute!

You can see the value and would like to contribute?! We are open to hearing from you.

See some items we need immediate contributions:

- CI improvement: implement more tests; mock provider API; improve linter items
- Documentation: Deployment documentation; Usage documentation
- Examples: Implement example playbooks

If you would like to contribute to any other item not listed above, feel free to open an issue or a Pull request. =]

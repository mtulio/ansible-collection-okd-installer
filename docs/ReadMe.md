# Ansible Collection okd_installer

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/release.yml/badge.svg)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/ci.yml/badge.svg?branch=main)
![](https://img.shields.io/ansible/role/59600)


Ansible Collection to install OKD clusters.

The okd_install Ansible Collection was designed to be distributed and easier to implement and deploy infrastructure resources required for OKD Installation, reusing the existing resources (modules and roles) from the Ansible community, implementing only the OKD specific roles, packaging together all necessary dependencies (external Roles).

The infrastructure provisioning was distributed into Stacks, then the Playbooks orchestrate the Stack provisioning by sending the correct embeded/user-provided variables to the Roles, which interacts with Cloud Provider API through oficial Ansible Modules. In general there is one Ansible Role for each stack. The Ansible Roles for Infrastructure stacks are not OKD specific, so it can be reused in other projects, and easily maintained by the community. The 'topologies' for each Roles are defined as variables included on OKD Ansible Collection to satisfy valid cluster topologies.

For example, these components are used on the Network Stack to provision the VPC on AWS:

- Playbook `playbooks/vars/aws/stack_network.yaml` implements the orchestration to create the VPC and required resources (Subnets, Nat and Internet Gateways, security groups, etc), then calls the Ansible Role `cloud_network`
- Var file `playbooks/vars/aws/network.yaml`: Defines the topology of the Network declaring the variable `cloud_networks` (required by role `cloud_network`). Can be replaced when setting `var_file`
- Ansible Role `cloud_network`: Resolve the dependencies and create the resources using community/vendor Ansible Modules, according the `cloud_networks` definition.
- Ansible modules from Community/Vendor: it is distributed as Collection. For AWS the community.aws and amazon.aws are used inside the Ansible Role `cloud_network`

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


## Requirements

- Python 3.8 or later

## Setup

Install ansible and dependencies:

```bash
pip install -r hack/requirements.txt
```

Clone the project
```bash
ansible-galaxy collection install mtulio.okd_installer
```

## Getting started

- [Install a cluster in AWS using UPI](./installing/aws-upi.md)


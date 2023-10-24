# Ansible Collection okd_installer

[![Project Status: WIP – Initial development is in progress, it is not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![](https://github.com/mtulio/ansible-collection-okd-installer/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mtulio/ansible-collection-okd-installer/actions/workflows/ci.yml)
[![](https://img.shields.io/ansible/collection/1867)](https://galaxy.ansible.com/mtulio/okd_installer)


Ansible Collection okd-installer allow you to keep infrastructure required to deploy
OKD/OCP as a code in non-integrated providrs or UPI installation method.

- [Summary](#summary)
- [Content](#content)
    - [Roles](#content-roles)
    - [Playbooks](#content-playbooks)
    - [Integrated Providers](#content-providers)
- [Requirements](#requirements)
    - [Quick Install](#content-quick-install)
- [Contribute](#contribute)

See next:

- [Getting Started](./Getting-started.md)
- [Installing](./Installing.md)
- [Usage](./Usage.md)
- [Cluster Installation Guides](#)
    - [AWS User-Provisioned Installation](./installing/aws-upi.md)
    - [AWS with Agnostic Installation](./installing/aws-agnostic.md)
    <!-- - [DigitalOcean with Agnostic Installation](./installing/digitalOcean-agnostic.md) -->
- [Onboarding](./Onboarding.md)


## Summary <a name="summary"></a>

The okd_install Ansible Collection was designed to be distributed and easier to implement and deploy infrastructure resources required for OKD Installation, reusing the existing resources (modules and roles) from the Ansible community, implementing only the OKD specific roles, packaging together all required dependencies (external Ansible Roles and modules).

The infrastructure provisioning is distributed into Stacks, then the Playbooks responsible to orchestrate the Stack provisioning, sends the correct user-provided variables to the Roles, which interacts with Cloud Provider API through oficial Ansible Modules. In general there is one Ansible Role for each stack. The Ansible Roles for Infrastructure stacks are not OKD specific, so it can be reused in other cloud infra provisioning projects, allowing more flexibility to be maintained by the community. The `topologies` for each Roles are defined as variables included on OKD Ansible Collection to satisfy valid cluster topologies.

For example, these are the components used on AWS to provision the Network Stack (VPC):

- Playbook `playbooks/vars/aws/stack_network.yaml` implements the orchestration to create the VPC and required resources (Subnets, Nat and Internet Gateways, security groups, etc), then calls the Ansible Role `cloud_network`
- Var file `playbooks/vars/aws/network.yaml`: Defines the topology of the Network declaring the variable `cloud_networks` (required by role `cloud_network`). Can be replaced when setting `var_file`
- Ansible Role `cloud_network`: Resolve the dependencies and create the resources using community/vendor Ansible Modules, according the `cloud_networks` definition.
- Ansible modules from Community/Vendor: it is distributed as Collection. For AWS the community.aws and amazon.aws are used inside the Ansible Role `cloud_network`

## Content <a name="content"></a>

That collection distribute a set of Ansible Roles and Playbooks used to provision the OKD cluster on specific Platform. Some of resources are managed in an external repository to keep it reusable, easy to maintain, and improve. The external resources are included as Git modules and updated once it needed (is validated).

### Roles <a name="content-roles"></a>

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

### Playbooks <a name="content-playbooks"></a>

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

### Integrated Cloud Provider <a name="content-providers"></a>

The matrix below shows the status of the Ansible Collection `okd-installer` integration* with the Cloud Provider and the installation Type:

| Platform/Install Type | IPI | UPI | Agnostic** |
| -- | -- | -- | -- |
| AWS | No | Yes | Yes |
| Azure | No | No | No |
| GCP | No | No | No |
| AlibabaCloud | No | No | No |
| IBMCloud | No | No | No |
| DigitalOcean* | -- | -- | No' |
| Vultr | -- | -- | No' |
| Ionos | -- | -- | No' |

- `No`: Provider is supported by OKD/OCP **and not** integrated on the Ansible Collection `okd-installer`
- `No'`: Provider is not supported by OKD/OCP **and not** integrated with  Ansible Collection `okd-installer`
- `Yes`: Provider is supported by OKD/OCP **and** integrated on the Ansible Collection `okd-installer`
- `Yes'`: Provider is not supported by OKD/OCP **and** integrated on the Ansible Collection `okd-installer`
- `--`: The provider is not supported by OKD/OCP (Only Agnostic Available)

*Provider integrated with Ansible Collection okd-installer. This integration is not related with OKD Platform integartion.
**Agnostic installation means that OKD there's no native integration with the Platform.

## Requirements <a name="requirements"></a>

- Python 3.8 or later
- Ansible 6 or later

### Quick Install <a name="content-quick-install"></a>

Install ansible and dependencies:

```bash
pip install -r hack/requirements.txt
```

Clone the project
```bash
ansible-galaxy collection install mtulio.okd_installer
```

## Contribute

Feel free to contribute with this repository.

To get started you can:

- Review the documentation
- Open Issues describing the problem you find into details
- Open Issues describing the new feature
- Open the PR with the change porposal


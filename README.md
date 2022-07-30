# ansible-collection-okd-installer

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/release.yml/badge.svg)
![](https://github.com/mtulio/ansible-role-cloud-dns/actions/workflows/ci.yml/badge.svg?branch=main)
![](https://img.shields.io/ansible/role/59600)


Ansible Collection for OKD Installation

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

- TBD

### Playbooks

Playbooks distributed on this Ansible Collection:

- TBD

## Supported Cloud Platforms

Supported Cloud Platforms* and installation types:

| Provider | IPI | UPI | None** |
| -- | -- | -- |
| AWS | No | Yes | Yes |
| Azure | No | No | No |
| GCP | No | No | No |
| AlibabaCloud | No | No | No |
| DigitalOcean | N/A | N/A | Yes |
| Vultr | N/A | N/A | No |
| OracleCLoud | N/A | N/A | No |


*The "supported" is not connected with Red Hat or OCP integration, but means the ability to use this Ansible Collection to create/install clusters on the provider.
**None means there is support to install OKD on this platform, but no native integration will be available on the OKD, which means every controller to interact with the Cloud Resource should be added separatelly.

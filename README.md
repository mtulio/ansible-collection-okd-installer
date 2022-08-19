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

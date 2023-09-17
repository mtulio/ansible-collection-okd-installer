# Dev Call: Cloud Provider Opportunities for OKD

Hey, are you looking for opportunities to explore OKD into other cloud providers
using okd-installer Collection? This section describes some opportunities
if you are looking for challenges!

Here are a matrix with existing Cloud Providers with Ansible automation, or API/SDK reference
if you would like to a challenge creating new modules:

| Provider Name | Ansible | Platform External:CCM/CSI |
| -- | -- | -- |
| Digital Ocean | [Collection](https://docs.ansible.com/ansible/latest/collections/community/digitalocean/index.html) | [CCM](https://github.com/digitalocean/digitalocean-cloud-controller-manager) / [CSI](https://github.com/digitalocean/csi-digitalocean) |
| Vultr Cloud | [Modules](https://github.com/ngine-io/ansible-collection-vultr) | [CCM](https://github.com/vultr/vultr-cloud-controller-manager) / [CSI](https://github.com/vultr/vultr-csi) |
| Hetzner Cloud | [Modules](https://github.com/ansible-collections/hetzner.hcloud) | [CCM](https://github.com/hetznercloud/hcloud-cloud-controller-manager) / [CSI](https://github.com/hetznercloud/csi-driver / Ansible modules) |
| IONOS | [Modules](https://github.com/ionos-cloud/module-ansible) | [CCM](https://github.com/23technologies/machine-controller-manager-provider-ionos) / CSI |
<!-- | CloudStack | [Modules](https://docs.ansible.com/ansible/latest/scenario_guides/guide_cloudstack.html) | [CCM](https://github.com/kubernetes-sigs/cluster-api-provider-cloudstack) / [CSI](https://github.com/apalia/cloudstack-csi-driver)  |
| Oracle Cloud | [Collection](https://oci-ansible-collection.readthedocs.io/en/latest/collections/oracle/oci/index.html) | [CCM](https://github.com/oracle/oci-cloud-controller-manager) / [CSI](https://github.com/oracle/oci-cloud-controller-manager/blob/master/container-storage-interface.md) |
| TecentCloud | [Inventory](https://github.com/tencentyun/ansible-tencentcloud/tree/master/inventory)/[Python SDK](https://github.com/TencentCloud/tencentcloud-sdk-python)/[Terraform](https://github.com/tencentcloudstack/terraform-provider-tencentcloud)  | [CCM](https://github.com/TencentCloud/tencentcloud-cloud-controller-manager) / [CSI](https://github.com/TencentCloud/kubernetes-csi-tencentcloud)|
| Huawei Cloud | [Modules](https://github.com/huaweicloud/huaweicloud-ansible-modules) | [CCM](https://github.com/kubernetes-sigs/cloud-provider-huaweicloud) / [CSI](https://github.com/huaweicloud/huaweicloud-csi-driver) |
| Baidu Cloud | [Python SDK](https://github.com/baidubce/bce-sdk-python) / [Terraform](https://registry.terraform.io/providers/baidubce/baiducloud/latest/docs) | [CCM](https://github.com/kubernetes-sigs/cloud-provider-baiducloud) / [CSI](https://github.com/baidubce/baiducloud-cce-csi-driver) |
| Outscale | [Modules](https://docs.ansible.com/ansible/latest/collections/cloudscale_ch/cloud/index.html#plugin-index)  | [CCM](https://artifacthub.io/packages/helm/osc-cloud-controller-manager/osc-cloud-controller-manager) / [CSI](https://artifacthub.io/packages/helm/osc-bsu-csi-dr) |
| Scaleway | [Modules](https://docs.ansible.com/ansible/latest/scenario_guides/guide_scaleway.html) | [CCM](https://github.com/scaleway/scaleway-cloud-controller-manager) / [CSI](https://github.com/scaleway/scaleway-csi) | -->


## Existing exploration / hacking / labs

### Digital Ocean

Looking for Digital Ocean installations? We need contributors! =]

Please take a look at the ongoing [PR #40](https://github.com/mtulio/ansible-collection-okd-installer/pull/40).

### IONOS

Looking for IONOS installations? Feel free to submit the contribution! =]

There is an exploration[1] using Official IONOS Ansible Collection and
the okd-installer Collection. Please take a look at the [PR #9](https://github.com/mtulio/ansible-collection-okd-installer/pull/9).

[1] https://docs.ionos.com/ansible/
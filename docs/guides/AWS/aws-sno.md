# AWS Single Node Openshift/OKD (SingleReplica Topology)

Install a single node replica OpenShift/OKD.

The steps will create every infrastrucure stack to deploy a Single Replicas OKD/OpenShift on AWS.

The following describes the cloud infrastructure resources created:

- VPC and it's subnets on a single AZ
- Security Groups
- Load Balancers for API (public and private) and Apps
- DNS Zones and RRs
- Compute resources: Bootstrap and single node control plane

## Deployment considerations

The deployment described in this document introduces a more performant disk layout to avoid disruptions and concurrency between resources in the same disk (by default), considering the capacity isolation.

The following disk layout is used when deploying in EC2 instance with `m6id.xlarge`:

- Ephemeral disk (local storage) for `/var/lib/containers`
- Dedicated etcd mounted in `/var/lib/etcd` in the second EBS using gp3

```text
$ cat ~/results/opct-sno-aws/sno2-run-lsblk.txt
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
nvme0n1     259:0    0   128G  0 disk 
|-nvme0n1p1 259:4    0     1M  0 part 
|-nvme0n1p2 259:5    0   127M  0 part 
|-nvme0n1p3 259:6    0   384M  0 part /boot
`-nvme0n1p4 259:7    0 127.5G  0 part /sysroot
nvme1n1     259:1    0    32G  0 disk 
`-nvme1n1p1 259:3    0    32G  0 part /var/lib/etcd
nvme2n1     259:2    0 220.7G  0 disk /var/lib/containers
```

Using this layout we decreased the amount of memory used by monitoring stack (Prometheus), and, consequently the etcd when using a single/shared-disk deployment. The API disruptions decreased drastically, allowing to use smaller instance types with 16GiB of RAM and 4 vCPU.

> TODO add metrics/graphs from the before/after improvements.

## Steps

- Generate the SNO ignitions
- Create the Stacks: Network, IAM, DNS, LB
- Create the Compute with ignition

### Create the configuration variables

Create the okd-installer configuration:

```bash
VARS_FILE=./vars-sno.yaml
cat << EOF > $VARS_FILE
provider: aws
cluster_name: sno-aws
version: 4.14.0-rc.0

config_base_domain: devcluster.openshift.com
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: ${HOME}/.openshift/pull-secret-latest.json
config_cluster_region: us-east-1

cluster_profile: SingleReplica
create_worker: no
destroy_bootstrap: no

config_compute_replicas: 0
config_controlplane_replicas: 1
cert_expected_nodes: 0
config_bootstrapinplace_disk: /dev/nvme0n1

# Choose the instance type for SNO node.
# NOTE: the okd-installer does not support yet the spot
#- m6i.xlarge: ~140/od ~52/spot
#- m6id.xlarge: ~173/od ~52/spot
#- m6idn.xlarge: ~232/od ~52/spot
#- r5d.xlarge: ~210/od ~52/spot
#- r6id.xlarge: ~220/od ~54/spot
#- t4g.xlarge: ~98/od 29/spot
#- m6gd.xlarge: ~131/od ~52/spot
#- r6gd.2xlaarge: ~168/od ~62/spot
controlplane_instance: m6id.2xlarge

# Patch manifests to:
# 1) mount ephemeral disk on /var/lib/containers
# 2) mount extra disk for etcd (/var/lib/etcd)
# 3) remove machine api objects
config_patches:
- mc_varlibcontainers
- mc_varlibetcd
- rm-capi-machines

cfg_patch_mc_varlibcontainers:
  device_path: /dev/nvme2n1
  device_name: nvme2n1
  machineconfiguration_roles:
  - master

EOF
```

Where:

- `cluster_profile: sno`: ...
- `create_worker: no`: ...
- `destroy_bootstrap: no`: ...
- `config_patches`: ...
- `cfg_patch_mc_varlibcontainers`: ...


### create cluster

- Create cluster:

```bash
ansible-playbook mtulio.okd_installer.create_all -e @$VARS_FILE
```

- Check resources:

```bash
$ KUBECONFIG=$HOME/.ansible/okd-installer/clusters/opct-sno/auth/kubeconfig oc get nodes
NAME             STATUS   ROLES                               AGE   VERSION
ip-10-0-50-187   Ready    control-plane,master,tests,worker   24m   v1.25.4+77bec7a

$ KUBECONFIG=$HOME/.ansible/okd-installer/clusters/opct-sno/auth/kubeconfig oc get co
```

- Destroy the bootstrap node:

```bash
ansible-playbook mtulio.okd_installer.destroy_bootstrap -e @$VARS_FILE
```

## Destroy

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```
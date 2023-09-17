## Destroy cluster

```bash
ansible-playbook mtulio.okd_installer.destroy_cluster \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```
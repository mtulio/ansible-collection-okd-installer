#### Approve certificates

The `create_all` already trigger the certificates approval with one default timeout. If the nodes was not yet joined to the cluster (`oc get nodes`) or still have pending certificates (`oc get csr`) due the short delay for approval, you can call it again with longer timeout:

- Approve the certificates (default execution)

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME}
```

- Change the intervals to check (example 5 minutes)

```bash
ansible-playbook mtulio.okd_installer.approve_certs \
    -e provider=${CONFIG_PROVIDER} \
    -e cluster_name=${CONFIG_CLUSTER_NAME} \
    -e certs_max_retries=3 \
    -e cert_wait_interval_sec=10
```
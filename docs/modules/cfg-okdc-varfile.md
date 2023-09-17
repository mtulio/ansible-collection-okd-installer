### Create the vars file

```bash
cat <<EOF > ${VARS_FILE}
provider: ${PROVIDER}
cluster_name: ${CLUSTER_NAME}
config_cluster_region: ${CLUSTER_REGION}

config_cluster_version: 4.14.0-rc.0
version: 4.14.0-rc.0

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: ${CLUSTER_DOMAIN}
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${HOME}/.openshift/pull-secret-latest.json"
EOF
```

# okd-installer config
cat <<EOF > ${VARS_FILE}
provider: ${CONFIG_PROVIDER}
config_platform: ${CONFIG_PLATFORM}
cluster_name: ${CLUSTER_NAME}
config_cluster_region: ${CLUSTER_REGION}

config_cluster_version: ${VERSION}
version: ${VERSION}

cluster_profile: ha
destroy_bootstrap: no

config_base_domain: ${CLUSTER_DOMAIN}
config_ssh_key: "$(cat ~/.ssh/openshift-dev.pub)"
config_pull_secret_file: "${PULL_SECRET_FILE}"
EOF
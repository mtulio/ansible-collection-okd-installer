#!/bin/bash

# Run playbook

export VARS_FILE="./vars-mock.yaml"
export AWS_MOCK_ENDPOINT_MOTO="http://localhost:3000"

export PLAY_NAME="${1}"
export PLAY_EXTRA_VARS="-e cert_approval_done=yes"

export PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-okd-fake.json"
declare -x CLUSTER_NAME

if [ -f $VARS_FILE ]; then
    CLUSTER_NAME="$(grep ^cluster_name ${VARS_FILE} | awk -F': ' '{print$2}')"
else
    rand_uuid="$(uuidgen | cut -d '-' -f1)"
    CLUSTER_NAME="mock-${rand_uuid}"
fi

create_pull_secret() {
    if [ -f $PULL_SECRET_FILE ]; then
        return
    fi
    cat <<EOF > "${PULL_SECRET_FILE}"
{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}
EOF
}

create_vars_file() {
    if [ -f $VARS_FILE ]; then
        return
    fi
    cat <<EOF > ${VARS_FILE}
version: 4.13.0
provider: aws
cluster_profile: ha

cluster_name: $CLUSTER_NAME
config_cluster_region: us-east-1

config_base_domain: fake.okd.io
config_ssh_key: "$(cat ~/.ssh/id_rsa.pub)"
config_pull_secret_file: ${PULL_SECRET_FILE}
EOF
}

play_run_mock_api_moto() {
    S3_URL="${AWS_MOCK_ENDPOINT_MOTO}" \
        AWS_URL="${AWS_MOCK_ENDPOINT_MOTO}" \
        EC2_URL="${AWS_MOCK_ENDPOINT_MOTO}" \
        AWS_ACCESS_KEY_ID='testing' \
        AWS_SECRET_ACCESS_KEY='testing' \
        AWS_SECURITY_TOKEN='testing' \
        AWS_SESSION_TOKEN='testing' \
        AWS_DEFAULT_REGION='us-east-1' \
        $@
}

play_run() {
    play_run_mock_api_moto ansible-playbook mtulio.okd_installer.$PLAY_NAME \
        -e @${VARS_FILE} -vvv $PLAY_EXTRA_VARS
}

play_config() {
    PLAT_EXTRA_VARS="-e mode=create" play_run $PLAY_NAME
}

play_create_node() {
    echo "# Running $PLAY_NAME (bootstrap)"
    PLAY_EXTRA_VARS="${PLAY_EXTRA_VARS} node_role=bootstrap" play_run $PLAY_NAME

    echo "# Running $PLAY_NAME (controlplane)"
    PLAY_EXTRA_VARS="${PLAY_EXTRA_VARS} node_role=controlplane" play_run $PLAY_NAME

    echo "# Running $PLAY_NAME (compute)"
    PLAY_EXTRA_VARS="${PLAY_EXTRA_VARS} node_role=compute" play_run $PLAY_NAME
}

create_pull_secret
create_vars_file

case $PLAY_NAME in
    "config") play_config;;
    "create_node") play_create_node;;
    *) play_run ;;
esac
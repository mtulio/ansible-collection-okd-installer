#!/usr/bin/env bash

export test_name=aws-none-sno
export test_env="okd-4.12.0-0"
export VARS_FILE="./vars-${test_name}.yaml"

test_dir="$(dirname "$0")"

source "$test_dir"/config/"$test_env".env && \
envsubst < "$test_dir"/config/"${test_name}".vars > $VARS_FILE

"$test_dir"/run-play-steps.sh create_all
"$test_dir"/run-play-steps.sh destroy_cluster
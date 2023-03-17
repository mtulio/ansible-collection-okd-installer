## OPCT setup

- Create the OPCT [dedicated] node

> https://redhat-openshift-ecosystem.github.io/provider-certification-tool/user/#option-a-command-line

```bash
# Create OPCT node
ansible-playbook mtulio.okd_installer.create_node \
    -e node_role=opct \
    -e @$VAR_FILE
```

- OPCT dedicated node setup

```bash

# Set the OPCT requirements (registry, labels, wait-for COs stable)
ansible-playbook ../opct/hack/opct-runner/opct-run-tool-preflight.yaml -e cluster_name=oci-t11 -D

oc label node opct-01.priv.ocp.oraclevcn.com node-role.kubernetes.io/tests=""
oc adm taint node opct-01.priv.ocp.oraclevcn.com node-role.kubernetes.io/tests="":NoSchedule

```

- OPCT regular

```bash
# Run OPCT
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 run -w

# Get the results and explore it
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 retrieve
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 results *.tar.gz
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 report *.tar.gz
```

- OPCT upgrade mode

```bash
# from a cluster 4.12.1, run upgrade conformance to 4.13
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 run -w \
  --mode=upgrade \
  --upgrade-to-image=$(oc adm release info 4.13.0-ec.2 -o jsonpath={.image})

# Get the results and explore it
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 retrieve
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 results *.tar.gz
~/opct/bin/openshift-provider-cert-linux-amd64-v0.3.0 report *.tar.gz
```

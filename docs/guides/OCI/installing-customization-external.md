> TODO:

- describe the step-by-step to create a cluster customizing CCM manifests (using from OCI CCM repo) to deploy OKD/OCP


```bash
ansible-playbook mtulio.okd_installer.install_clients -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-config -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-manifests -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_network -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_dns -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.stack_loadbalancer -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=patch-manifests -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.config -e mode=create-ignitions -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.os_mirror -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=bootstrap -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=controlplane -e @$VARS_FILE
ansible-playbook mtulio.okd_installer.create_node -e node_role=compute -e @$VARS_FILE
export KUBECONFIG=${HOME}/.ansible/okd-installer/clusters/${CLUSTER_NAME}/auth/kubeconfig
oc adm certificate approve $(oc get csr  -o json |jq -r '.items[] | select(.status.certificate == null).metadata.name')

ansible-playbook mtulio.okd_installer.destroy_cluster -e @$VARS_FILE
```
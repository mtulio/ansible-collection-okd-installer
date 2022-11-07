# Install Guide for `openshift-install` binary

The okd-installer Collection calls the `openshift-install` binary to setup the cluster artifacts (ignition files) to install the cluster.

It should be available on the path `~/.ansible/okd-installer/bin/openshift-install`.

If you would like to provide your own installer binary, you should replace that path to yours. The openshift client (`oc`) is also required to be available on the path `~/.ansible/okd-installer/bin/oc`.

## Installing the Clients

The okd-installer Collection provides the playbook `install_clients` to help you to install new clients. It requires the environment variable to be set `CONFIG_PULL_SECRET_FILE`.

The binary path of the clients used by installer is `${HOME}/.ansible/okd-installer/bin`*, so the utilities like `openshift-installer` should be in this path.

*it will be more flexible in the future.

To check if the clients used by installer is present, run the client check:

```bash
ansible-playbook mtulio.okd_installer.install_clients
```

To install the clients you can run set the version and run:

```bash
ansible-playbook mtulio.okd_installer.install_clients -e version=4.11.4
```

## Clean-up old binaries

By default the binaries will be saved with no remove lifecycle.

```bash
$ tree ${HOME}/.ansible/okd-installer/bin
/home/user/.ansible/okd-installer/bin
├── kubectl -> /home/user/.ansible/okd-installer/bin/kubectl-linux-4.11.4
├── kubectl-linux-4.11.0
├── kubectl-linux-4.11.0-0.okd-2022-08-20-022919
├── kubectl-linux-4.11.4
├── kubectl-linux-4.11.5
├── kubectl-linux-4.11.8
├── oc -> /home/user/.ansible/okd-installer/bin/oc-linux-4.11.4
├── oc-linux-4.11.0
├── oc-linux-4.11.0-0.okd-2022-08-20-022919
├── oc-linux-4.11.4
├── oc-linux-4.11.5
├── oc-linux-4.11.8
├── openshift-install -> /home/user/.ansible/okd-installer/bin/openshift-install-linux-4.11.4
├── openshift-install-linux-4.11.0
├── openshift-install-linux-4.11.0-0.okd-2022-08-20-022919
├── openshift-install-linux-4.11.4
├── openshift-install-linux-4.11.5
└── openshift-install-linux-4.11.8
```

You can remove the desired binaries manually.

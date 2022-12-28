# AWS deployment using Ansible Collection okd-installer

> This document is under development to be published on https://www.okd.io/guides/overview/

This document describes how to deploy OKD clusters on AWS with user-provisioned infrastructure, using the okd_installer Ansible Collection to provision the cloud resources.

The Ansible Collection okd_installer is one IaaC alternative for admins who would like to manage the cloud infrastructure as a code, provisioning custom OKD cluster topologies.

With the Ansible Collection okd_installer you can provision and customize pieces (Stacks) of the infrastructure to host OKD/OCP.

Every section will points to the default variables provided by the Collection. It can be used as a baseline to create your own to customize the infrastructure.

Table of Contents:

- Prepare the environment
    - Install the Ansible Collection
    - Setup the variables
- OKD Create Cluster
    - Install the OKD clients (openshift-install and oc)
    - Generate the Cluster Config
    - Create the Stacks
        - Network Stack
        - IAM Stack
        - DNS Stack
        - Load Balancer Stack
        - Compute Stack: Bootstrap
        - Compute Stack: Control Plane
        - Compute Stack: Compute
            - Approve certificates
        - Load Balancer Stack for Default Router
- OKD Destroy Cluster


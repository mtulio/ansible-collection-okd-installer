# Developr Guide - Tests

!!! warning "TODO / WIP page"
    This documentation is in progress and contains fragments to use external load balancer which is not yet tested. The goal is to validate each one.


- Describe the steps to create new config provider

The Config provider is responsible to generate the cluster configuration used on Day-0 by the internal role `config` and implements basic the following modes:

- create config
- create manifests
- patch manifests
- create ignitions
- create all

The existing config provider is:

- openshift-tests

Ongoing config provider:

- [assisted-installer](https://github.com/mtulio/ansible-collection-okd-installer/pull/28)


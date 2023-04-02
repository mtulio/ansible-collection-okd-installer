# Why okd-installer Ansible Collection?

There were a few source of inspirrations and needs to created this project:

- decrease manual steps to create infrastructure when installing agnostic platform - initially when using AWS as a provider
    - why not using AWS integration? The goal was to exercise and test agnostic installation (Platform=None) on internal projects
- provide alternative to use Infra as a Code to install OCP/OKD, focused on infrastructure resources
- create generic UPI to deploy OpenShift/OKD exploring the rich ecosystem of Ansible Modules/Collections for existing Cloud Providers, targeting to decrease the infra time taken when provisoining onto non-integrated providers
- decrease repeated steps, focusing in platform specifics
- allow high level of customization without needing to inject new code to the codebase
- Allow non-integrated providers on OCP/OKD codebase to automate the installation of UPI method
- Allow non-integrated providers on OCP/OKD codebase to extend kubernetes with Platform External mode

> TBC
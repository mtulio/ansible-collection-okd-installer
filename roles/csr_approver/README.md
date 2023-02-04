okd_approve_certificates
========================

OKD/OpenShift CSR Approver for worker nodes.

This role will check the desired worker node count and approve the CSR right after the cluster is installed.

Requirements
------------

okd-installer Collection

Role Variables
--------------

- `certs_max_retries`: Loop count to try to get pending CSRs to be approved
- `cert_wait_interval_sec`: Interval in seconds between each retry

Dependencies
------------

None.

Example Playbook
----------------

~~~
- name: OKD Installer | Create all | create stack | approve certs
  ansible.builtin.import_playbook: approve_certs.yaml
  vars:
    certs_max_retries: 8
    cert_wait_interval_sec: 60
  when:
    - (config_provider == 'aws') or (config_platform == 'none')
~~~

License
-------

Apache-v2

Author Information
------------------

Ansible Collection OKD Installer contributors.

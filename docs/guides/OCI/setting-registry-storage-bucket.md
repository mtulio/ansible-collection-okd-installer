# OCI Image Registry - Use S3 compatibility URL for persistent storage

> WIP

https://docs.okd.io/latest/registry/configuring_registry_storage/configuring-registry-storage-aws-user-infrastructure.html

Steps to use the OCI S3 Compatibility API to set the persistent storage for the OpenShift Image Registry with OCI Bucket service.

Steps:

- Create access Key
- Create the secret used by image-registry
- Edit the image registry object adding the s3 configuration
- Test it

### Distribution OKD SCOS

To obtain the openshift installer and client, visit releases for stable versions or the [CI Release Controller](https://amd64.origin.releases.ci.openshift.org/) for nightlies.

Export the variables related to deployment environment:

```bash
DISTRIBUTION="okd"
RELEASE_REPO=quay.io/okd/scos-release
VERSION=4.14.0-0.okd-scos-2023-08-17-022029
RELEASE_VERSION=$VERSION
PULL_SECRET_FILE="{{ playbook_dir }}/../tests/config/pull-secret-okd-fake.json"
```
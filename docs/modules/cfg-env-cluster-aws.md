
### Required environment variables

Export the variables related to the cluster:

```bash
# Cluster Install Configuration
CLUSTER_NAME="mycluster"

# Provider Information
PROVIDER=aws
CLUSTER_REGION=us-east-1
CLUSTER_DOMAIN="aws.example.com"

# AWS Credentials
AWS_ACCESS_KEY_ID="AK..."
AWS_SECRET_ACCESS_KEY="[superSecret]"
AWS_DEFAULT_REGION="${CLUSTER_REGION}"
```
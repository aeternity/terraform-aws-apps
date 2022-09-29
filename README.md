# Terraform code for aepps infrastructure.

## Environments

Each environment is managed in a separate Terraform workspace.
All environments must be in parity in terms of services they provide,
however some variables might differ like instance types, numbers etc.

Environment configuration must be set only in `local.env_config` in main.tf module.

## Terraform authentication

The EKS module in the terraform configuraiton needs a special role to manage a cluster.
That means one have to use a session with assumed role, even full admins.

Example:

```bash
./script/auth.sh dev-wgt7
export AWS_PROFILE=aeternity-session
```

## EKS Authentication

EKS authentication needs explicit IAM role that can be get from `terraform output cluser_admin_iam_role_arn`.

An exmaple for the `dev` cluster:

```bash
aws eks update-kubeconfig --name dev-wgt7 --role-arn arn:aws:iam::106102538874:role/dev-wgt7-cluster-admin --alias dev-wgt7 --profile aeternity
```

## Opensearch module,resources and deployment notes.

The opensearch module is deployed with internal database for authentication.
It requires master user and password, which currenty are dynamic from terrafrom. 

The additional Opnensearch resources, which are not supported by terraform provider are implemented with bash script and local exec resource.  
Please keep in mind that these terraform resources are not aware of curl command result, so check carefully the terraform output.

Opensearch Backend Roles: 

1. es_backend_role_cluster - Adding the eks cluster admin role to all_access role in Opensearch.
2. es_backend_role_worker - - Adding the eks worker role to all_access role in Opensearch.
3. es_aws_iam_service_linked_role - The AWS linked role has a limitation to be applied once per account , so the es one is applied only in dev as firstly provisioned environment.If you need different approach for some reason , the code can be changed.
4. fluentbit aws_iam_policy_document - the policy allow access to Opensearch domain from eks nodes.

Opensearch resources:

1. ism_rollover_index_templates - creates every new fluent-bit index with alias fluentbit, which is used by fluent-bit agent.This allows successfull rollover and agent to continue sent logs to the index.
2. fluent_bit_index - The initial fluet-bit index.
3. fluent_bit_rollover_policy - the rollover polocy for the fluent-bit indexes. 

Once all Opensearch infrastructure resources are deployed, you can take a look the gitops repo.  
Link to fluent-bit chart deploy(change the branch for each environment): https://github.com/aeternity/gitops-tools/tree/dev/fluent-bit.

**IMPORTANT: All terraform resources for Opensearch should be succesfully deployed before deployment of the fluent-bit agent to avoid unnecessary cost.**

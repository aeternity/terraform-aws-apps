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
./scripts/auth.sh dev-wgt7
export AWS_PROFILE=aeternity-session
```

## EKS Authentication

EKS authentication needs explicit IAM role that can be get from `terraform output cluser_admin_iam_role_arn`.

An exmaple for the `dev` cluster:

```bash
aws eks update-kubeconfig --name dev-wgt7 --role-arn arn:aws:iam::106102538874:role/dev-wgt7-cluster-admin --alias dev-wgt7 --profile aeternity
```

## Destroy

### VPC

The ingress load balancer must be deleted manually before destorying the cluster.

### Buckets

All S3 buckets must be empty prior deletion:
- aeternity-loki-chunks-*
- aeternity-loki-ruler-*
- aeternity-velero-backup-*
- aeternity-graffiti-server-*

### Auth
After first pass of terraform destroy the cluster admin will be deleted and start getting auth errors.

The state of k8s cluster auth has to be deleted and then run destroy again:
```shell
terraform state rm "module.eks.kubernetes_config_map.aws_auth[0]"
```

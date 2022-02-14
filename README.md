# Terraform code for aepps infrastructure.

## Opensearch module,resources and deployment notes.

The opensearch module is deployed with internal database for authentication.
It requires master user and password. 
Currently we are using git-secret to keep the master user password per environment as secret in 'main.auto.tfvars'.
Link to git-secret : https://git-secret.io/.
The pgp key is stored in our vault server: https://vault.ops.aeternity.com:18200/ui/vault/auth.
The secret is name gpg_passphrase.
The used email for gpg key: aeternity@aeternity.com.

The additional Opnensearch resources, which are not supported by terraform provider are implemented with terraform null resource and local exec.
Please keep in mind that these terraform resources are not aware of curl command result, so check carefully the result.

Opensearch Backend Roles: 

1. es_backend_role_cluster - Adding the eks cluster admin role to all_access role in Opensearch.
2. es_backend_role_worker - - Adding the eks worker role to all_access role in Opensearch.
3. es_aws_iam_service_linked_role - The AWS linked role has a limitation to be applied once per account , so the es one is applied only in dev as firstly provisioned environment.If you need different approach for some reason , the code can be changed.
4. fluentbit aws_iam_policy_document - the policy allow access to Opensearch domain from eks nodes.

Opensearch resources:

1. ism_rollover_index_templates - creates every new fluent-bit index with alias fluentbit, which is used by fluent-bit agent.This allows successfull rollover and agent to continue sent logs to the index.
2. fluent_bit_index - The initial fluet-bit index.
3. fluent_bit_rollover_policy - the rollover polocy for the fluent-bit indexes. 

Once all Opensearch infrastructure resources are deployed, you can refer to gitops repo.
The fluent-bit chart deploy is here(change the branch for each environment): https://github.com/aeternity/gitops-tools/tree/dev/fluent-bit

**IMPORTANT: All terraform resources for Opensearch should be succesfully deployed before deployment of the fluent-bit agent.**

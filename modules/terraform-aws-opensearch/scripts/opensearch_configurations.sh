#!/bin/bash

if [ ${#@} -lt 5 ]; then
    echo "usage: $0 [master_user_password] [master_user] [cluster_name] [cluster_iam_role_arn] [worker_iam_role_arn] [index_name] [index_alias]"
    exit 1;
fi

MASTER_USER_PASSWORD=$1
MASTER_USER=$2
CLUSTER_NAME=$3
CLUSTER_IAM_ROLE_ARN=$4
WORKER_IAM_ROLE_ARN=$5
ROLES_MAPPING_URL="https://$3.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty"
ROLES_MAPPING_METHOD="PATCH"
ISM_URL="https://$3.aepps.com/_index_template/ism_rollover?pretty"
ISM_METHOD="PUT"
CLUSTER_ROLE_JSON="[{\"op\": \"add\", \"path\": \"/backend_roles\", \"value\": [\"$CLUSTER_IAM_ROLE_ARN\"]}]"
WORKER_ROLE_JSON="[{\"op\": \"add\", \"path\": \"/backend_roles\", \"value\": [\"$WORKER_IAM_ROLE_ARN\"]}]"
ISM_JSON="{\"index_patterns\": [\"$6*\"],\"template\": {\"settings\": {\"plugins.index_state_management.rollover_alias\": \"fluentbit\"}}}"
INDEX_URL="https://$3.aepps.com/$6-000001" #fluent-bit-000001
INDEX_JSON="{\"aliases\": {\"$7\": {\"is_write_index\": true}}}"
INDEX_METHOD="PUT"
ROLLOVER_POLICY_URL="https://$3.aepps.com/_plugins/_ism/policies/$6-rollover-$3"
ROLLOVER_POLICY_METHOD="PUT"
ROLLOVER_POLICY_JSON="
        {
            \"policy\": {
                \"policy_id\": \"rollover\",
                \"description\": \"A simple default policy that rollover and deletes old indicies.\",
                \"default_state\": \"rollover\",
                \"states\": [
                    {
                        \"name\": \"rollover\",
                        \"actions\": [
                            {
                                \"rollover\": {
                                    \"min_index_age\": \"1d\"
                                }
                            }
                        ],
                        \"transitions\": [
                            {
                                \"state_name\": \"delete\",
                                \"conditions\": {
                                    \"min_index_age\": \"1d\"
                                }
                            }
                        ]
                    },
                    {
                        \"name\": \"delete\",
                        \"actions\": [
                            {
                                \"delete\": {}
                            }
                        ],
                        \"transitions\": []
                    }
                ],
                \"ism_template\": [
                    {
                        \"index_patterns\": [
                            \"$7\"
                        ],
                        \"priority\": 100,
                        \"last_updated_time\": 1643744811677
                    }
                ]
            }
        }"

function rest_call {
  curl -sS -u "$1:$2" -X $3 -H 'Content-Type: application/json' $4 -d "$5"
}

rest_call $MASTER_USER $MASTER_USER_PASSWORD $ROLES_MAPPING_METHOD $ROLES_MAPPING_URL "$CLUSTER_ROLE_JSON"
sleep 10
rest_call $MASTER_USER $MASTER_USER_PASSWORD $ROLES_MAPPING_METHOD $ROLES_MAPPING_URL "$WORKER_ROLE_JSON"
sleep  10
echo "ISM"
rest_call $MASTER_USER $MASTER_USER_PASSWORD $ISM_METHOD $ISM_URL "$ISM_JSON"
sleep 10
echo "INDEX"
rest_call $MASTER_USER $MASTER_USER_PASSWORD $INDEX_METHOD $INDEX_URL "$INDEX_JSON"
sleep 10
echo "ROLLOVER_POLICY"
rest_call $MASTER_USER $MASTER_USER_PASSWORD $ROLLOVER_POLICY_METHOD $ROLLOVER_POLICY_URL "$ROLLOVER_POLICY_JSON"

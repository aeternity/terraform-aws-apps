#!/bin/bash

if [ ${#@} -lt 5 ]; then
    echo "usage: $0 [master_user_password] [master_user] [cluster_name] [cluster_iam_role_arn] [worker_iam_role_arn]"
    exit 1;
fi

MASTER_USER_PASSWORD=$1
MASTER_USER=$2
CLUSTER_NAME=$3
CLUSTER_IAM_ROLE_ARN=$4
WORKER_IAM_ROLE_ARN=$5


curl -sS -u "$MASTER_USER:$MASTER_USER_PASSWORD" \
        -X PATCH \
        https://$CLUSTER_NAME.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty \
        -H 'Content-Type: application/json' \
        -d'
        [
          {
            "op": "add", "path": "/backend_roles", "value": ["$CLUSTER_IAM_ROLE_ARN"]
          }
        ]
        '

curl -sS -u "$MASTER_USER:$MASTER_USER_PASSWORD" \
        -X PATCH \
        https://$CLUSTER_NAME.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty \
        -H 'Content-Type: application/json' \
        -d'
        [
          {
            "op": "add", "path": "/backend_roles", "value": ["$WORKER_IAM_ROLE_ARN"]
          }
        ]
        '

curl -sS -u "$MASTER_USER:$MASTER_USER_PASSWORD" \
        -X PUT \
        https://$CLUSTER_NAME.aepps.com/_index_template/ism_rollover?pretty \
        -H 'Content-Type: application/json' \
        -d'
        {
          "index_patterns": ["fluentbit-index*"],
          "template": {
          "settings": {
            "plugins.index_state_management.rollover_alias": "fluentbit"
          }
        }
        }
        '

curl -sS -u "$MASTER_USER:$MASTER_USER_PASSWORD" \
        -X PUT \
        https://$CLUSTER_NAME.aepps.com/fluent-bit-000001 \
        -H 'Content-Type: application/json' \
        -d'
        {
          "aliases": {
            "fluentbit": {
              "is_write_index": true
            }
          }
        }
        '

curl -sS -u "$MASTER_USER:$MASTER_USER_PASSWORD" \
        -X PUT \
        https://$CLUSTER_NAME.aepps.com/_plugins/_ism/policies/fluent-bit-index-rollover-$CLUSTER_NAME \
        -H 'Content-Type: application/json' \
        -d'
        {
            "policy": {
                "policy_id": "rollover",
                "description": "A simple default policy that rollover and deletes old indicies.",
                "default_state": "rollover",
                "states": [
                    {
                        "name": "rollover",
                        "actions": [
                            {
                                "rollover": {
                                    "min_index_age": "1d"
                                }
                            }
                        ],
                        "transitions": [
                            {
                                "state_name": "delete",
                                "conditions": {
                                    "min_index_age": "1d"
                                }
                            }
                        ]
                    },
                    {
                        "name": "delete",
                        "actions": [
                            {
                                "delete": {}
                            }
                        ],
                        "transitions": []
                    }
                ],
                "ism_template": [
                    {
                        "index_patterns": [
                            "fluentbit-index*"
                        ],
                        "priority": 100,
                        "last_updated_time": 1643744811677
                    }
                ]
            }
        }
        '

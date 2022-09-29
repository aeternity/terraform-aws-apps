#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <cluster name>"
  exit 0
fi

# check for jq
command -v jq >/dev/null 2>&1 || { echo >&2 "You need to install jq for executing this script."; exit 1; }

CLUSTER_NAME=${1:?}

AWS_MAIN_PROFILE=${AWS_MAIN_PROFILE:-"aeternity"}
AWS_SESSION_PROFILE=${AWS_SESSION_PROFILE:-"aeternity-session"}
AWS_DEFAULT_REGION=eu-central-1
AWS_ROLE_ARN="arn:aws:iam::106102538874:role/$CLUSTER_NAME-cluster-admin"

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

export AWS_PROFILE=$AWS_MAIN_PROFILE
credentials=$(aws sts assume-role --role-arn ${AWS_ROLE_ARN:?} --role-session-name "$AWS_SESSION_PROFILE" --query 'Credentials' --output json)

AWS_ACCESS_KEY_ID=$(echo "$credentials" | jq -r '.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$credentials" | jq -r '.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$credentials" | jq -r '.SessionToken')

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $AWS_SESSION_PROFILE 
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $AWS_SESSION_PROFILE 
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile $AWS_SESSION_PROFILE 
aws configure set region $AWS_DEFAULT_REGION --profile $AWS_SESSION_PROFILE
echo "AWS profile "$AWS_SESSION_PROFILE" has been updated."

#export AWS_PROFILE=$AWS_SESSION_PROFILE

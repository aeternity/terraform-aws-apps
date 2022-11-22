#!/bin/bash

# Gracefully rotate EKS nodes
# Example : ./rotate-eks-nodes.sh <clusterId>

set -euo pipefail

cluster=$1

instances=$(aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/$cluster,Values=owned" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].{"instanceId": InstanceId, "dnsName": PrivateDnsName}' --output text)
groups=$(aws autoscaling describe-tags --filters "Name=Key,Values=kubernetes.io/cluster/$cluster" --query 'Tags[].ResourceId' --output text)

# for group in $groups; do
#     desired=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$group" --query 'AutoScalingGroups[].DesiredCapacity' --output text)
#     newDesired="$((desired * 2))"
#     echo "Doubling ASG capacity from $desired to $newDesired"
#     aws autoscaling set-desired-capacity --auto-scaling-group-name "$group" --desired-capacity "$newDesired"
# done

# echo "Wait 300s for new nodes"
# sleep 300

echo "Cordon all old instances"
echo "$instances" | while read instance; do
    instanceDns=$(echo "$instance" | cut -f1)
    instanceId=$(echo "$instance" | cut -f2)
    echo "Cordon instance $instanceDns..."
    kubectl --context $cluster cordon "$instanceDns"
done

echo "Drain and terminate old instances"
echo "$instances" | while read instance; do
    instanceDns=$(echo "$instance" | cut -f1)
    instanceId=$(echo "$instance" | cut -f2)

    # Cannot delete Pods not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet (use --force to override)
    # Cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore)
    # Cannot delete Pods with local storage (use --delete-local-data to override)
    # The flags above are needed for drain command to succeed, otherwise drain doesn't happen and the errors above are shown
    # It could be that the machine is already gone because of other reasons, that's ok.
    echo "Draining $instanceDns"
    kubectl --context $cluster drain --force --ignore-daemonsets --delete-local-data "$instanceDns" || true

    # It could be that the machine is already gone because of other reasons, that's ok.
    echo "Terminate $instanceId"
    aws autoscaling terminate-instance-in-auto-scaling-group --instance-id "$instanceId" --should-decrement-desired-capacity || true
done

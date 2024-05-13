#!/bin/bash -e

prefix=$(mktemp -u)

[ -f $prefix.task-defs ] || aws --region $AWS_REGION --output text ecs list-task-definitions --query 'taskDefinitionArns[].[@]' | sort > $prefix.task-defs
[ -f $prefix.clusters ] || aws --region $AWS_REGION --output text ecs list-clusters --query 'clusterArns[].[@]' > $prefix.clusters

if [ ! -f $prefix.clusters ]; then
	cluster_id=0
	while read cluster; do 
		aws --region $AWS_REGION --output text ecs list-services --cluster $cluster --query 'serviceArns[].[@]' > $prefix.clusters.$cluster_id
		cluster_id=$(( cluster_id + 1 ))
	done < $prefix.clusters
fi

if [ ! -f $prefix.active-task-defs ]; then
	cluster_id=0
	while read cluster; do 
		while read service; do 
			aws --region $AWS_REGION --output text ecs describe-services --cluster $cluster --services $service --query 'services[].taskDefinition'
		done < $prefix.clusters.$cluster_id
	
		cluster_id=$(( cluster_id + 1 ))
	done < $prefix.clusters | sort > $prefix.active-task-defs
fi

[ -f $prefix.orphaned-task-defs ] || diff $prefix.task-defs $prefix.active-task-defs | grep '^<' | awk '{ print $2 }' > $prefix.orphaned-task-defs

while read task_def; do
	if ! aws --region $AWS_REGION ecs deregister-task-definition --no-cli-pager --task-definition $task_def; then
		sleep 60
		aws --region $AWS_REGION ecs deregister-task-definition --no-cli-pager --task-definition $task_def
	fi
done < $prefix.orphaned-task-defs

rm $prefix.*


#!/bin/bash -e

filters=()
[ -z "$2" ] || filters+=( --tag-filters )
while [ -n "$2" ]; do
	filters+=( "Key=$1,Values=$2" )
	shift 2
done

aws --region $AWS_REGION --no-cli-pager resourcegroupstaggingapi get-resources "${filters[@]}"

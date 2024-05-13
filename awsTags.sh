#!/bin/bash -e

filter=()
exclude=()
declare -A project=()

mode=
while [ -n "$1" ]; do
	if [[ "$1" =~ [-+=] ]]; then
		mode=$1
		shift
		continue
	fi

	case "$mode" in
		=)
			if [ -z "$2" ]; then
				echo "Invalid number of parameters for filter. Required 2. Name and value." >&2
				exit 1
			fi
		
			filter+=( "Key=$1,Values=$2" )

			project[$1]=1
			shift 2
		;;
		-)
			if [ -z "$2" ]; then
				echo "Invalid number of parameters for exclusions. Required 2. Name and value." >&2
				exit 1
			fi

			exclude+=( 'Key == `'$1'` && Value != `'$2'`' )

			project[$1]=1
			shift 2
		;;
		+)
			if [ -z "$1" ]; then
				echo "Invalid number of parameters for projection. Required 1. Name." >&2
				exit 1
			fi

			project[$1]=1
			shift
		;;
		*)
			echo "Unknow mode: $mode" >&2
			echo "Valid modes:" >&2
			echo "+: Include" >&2
			echo "-: Exclude" >&2
			exit 1
		;;
	esac
	
done

[ -z "${filter[@]}" ] || filter=( --tag-filters "${filter[@]}" )

query='{ "ResourceTagMappingList": ResourceTagMappingList['
#?Tags[?Key == `'$1'` && Value != `'$2'`]
query="$query]"

project_keys=${!project[@]}

if [ -n "${project_keys[@]}" ]; then
	query="$query.{\"ResourceARN\": ResourceARN, Tags: ["
fi

query_str=
for key in ${project_keys[@]}; do
	[ -z "$query_str" ] || query_str="$query_str,"
	query_str="$query_str{ \"Key\": \`$key\`, \"Value\": Tags[?Key == \`$key\`] | [0].Value }"
done

if [ -n "${project_keys[@]}" ]; then
	query="$query$query_str] }}"
fi

aws --region $AWS_REGION --no-cli-pager resourcegroupstaggingapi get-resources "${filter[@]}" --query "${query[*]}"


#!/bin/bash -ex

include=()
exclude=()

mode=
while [ -n "$1" ]; do
	if [[ "$1" =~ [-+] ]]; then
		mode=$1
		shift
		continue
	fi

	case "$mode" in
		+)
			if [ -z "$2" ]; then
				echo "Invalid number of parameters for inclusions. Required 2. Name and value." >&2
				exit 1
			fi
		
			include+=( "Key=$1,Values=$2" )
			shift 2
		;;
		-)
			if [ -z "$2" ]; then
				echo "Invalid number of parameters for inclusions. Required 2. Name and value." >&2
				exit 1
			fi

			exclude+=( 'ResourceTagMappingList[?Tags[?Key == `'$1'` && Value != `'$2'`]]' )
			shift 2
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

[ -z "${include[@]}" ] || include=( --tag-filters "${include[@]}" )
[ -z "${exclude[@]}" ] || exclude=( --query "${exclude[@]}" )

aws --region $AWS_REGION --no-cli-pager resourcegroupstaggingapi get-resources "${include[@]}" "${exclude[@]}"

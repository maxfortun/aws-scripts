#!/bin/bash -e

topicName=$1
message=$2

AWS=aws
if [ -z "$topicName" ]; then
	echo "Usage: $0 <topicName> <message|file>"
	echo "e.g. $0 sns-topic "'"{\"name\": \"value\" }"'
	echo "e.g. $0 sns-topic file.json"
	$AWS --region $AWS_REGION --output text sns list-topics --query 'Topics[].[TopicArn]' | sed 's/^.*://g'
	exit 1
fi

topicArn=$($AWS --region $AWS_REGION --output text sns list-topics --query "Topics[?contains(TopicArn,\`$topicName\`)]")

if [ -f "$message" ]; then
	message=$(cat "$message")
fi

$AWS --region $AWS_REGION sns publish --topic-arn "$topicArn" --message "$message"

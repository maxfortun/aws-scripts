#!/bin/bash

now=$(date +'%s')
endDate=$(date -d "@$now" +'%Y-%m-%d')
days=1
start=$(( now - ( 60 * 60 * 24 * $days ) ))
startDate=$(date -d "@$start" +'%Y-%m-%d')

AWS=/usr/bin/aws 

$AWS --output text ce get-cost-and-usage --time-period "Start=${startDate},End=${endDate}" --granularity DAILY --metrics UsageQuantity --group-by Type=DIMENSION,Key=USAGE_TYPE

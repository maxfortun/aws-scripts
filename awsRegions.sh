#!/bin/bash

/usr/bin/aws --region $AWS_REGION --output text ec2 describe-regions --query 'sort_by(Regions, &RegionName) | [].[RegionName]'

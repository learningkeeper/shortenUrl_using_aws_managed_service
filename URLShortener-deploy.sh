#!/bin/bash 
set -xe
##put multiplle cf file inside the array for iteration
Files=("./URLShortener.yaml")
AWS_CLI_ARGS=""
STACK_NAME="URLShortener"
PARAMETER="./URLShortener.properties"

# For manual use
# REGION=ap-northeast-1
# AWS_CLI_ARGS="--profile=$PROFILE --region $REGION"



for f in "${Files[@]}"
do

#validate cloudformation yaml 
aws $AWS_CLI_ARGS \
    cloudformation validate-template \
    --template-body file://$f

# get changset for inpsection
CHANGESET=$( \
	aws $AWS_CLI_ARGS \
    cloudformation deploy \
	--template-file $f \
    --parameter-overrides $(cat $PARAMETER) \
	--capabilities CAPABILITY_IAM \
	--stack-name $STACK_NAME \
	--no-fail-on-empty-changeset \
	--no-execute-changeset > /dev/null && \
	aws $AWS_CLI_ARGS \
    cloudformation list-change-sets \
	--stack-name $STACK_NAME | \
	jq -r '.Summaries |
	sort_by(.CreationTime) |
	.[-1].ChangeSetId')

DESCRIBE_CHANGE_SET=$(aws $AWS_CLI_ARGS \
    cloudformation describe-change-set \
	--change-set-name $CHANGESET \
	--query "Changes[].ResourceChange")

# delete the 
aws $AWS_CLI_ARGS \
    cloudformation delete-change-set \
	--change-set-name $CHANGESET

aws $AWS_CLI_ARGS \
    cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file $f \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides `cat $PARAMETER` \
    --no-fail-on-empty-changeset
    
aws $AWS_CLI_ARGS \
        cloudformation describe-stack-events \
        --stack-name $STACK_NAME
done

# Snitize the lab
#aws cloudformation delete-stack --stack-name $STACK_NAME
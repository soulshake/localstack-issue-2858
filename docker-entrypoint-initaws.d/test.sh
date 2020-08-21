#!/bin/bash

apk add jq

red='\033[0;31m'
reset='\033[0m'

echo -e "$red Starting user signup flow $reset"

USER_EMAIL=foo@example.com

# Create Lambda
awslocal lambda delete-function --function-name test || true
lambda_arn="$(awslocal lambda create-function --function-name test --runtime nodejs12.x --handler cognito-pre-token-generation-lambda-trigger.handler --zip-file fileb:///src/cognito-pre-token-generation-lambda-trigger.zip --role whatever | jq -r .FunctionArn)"

## Create pool and client

lambda_config='{
    "PreTokenGeneration": "'$lambda_arn'",
    "PreAuthentication": "'$lambda_arn'",
    "PostAuthentication": "'$lambda_arn'"
}'

pool_id=$(awslocal cognito-idp create-user-pool --pool-name test --lambda-config "$lambda_config" | jq -rc ".UserPool.Id")
client_id="$(awslocal cognito-idp create-user-pool-client --user-pool-id "$pool_id" --client-name test-client | jq -rc ".UserPoolClient.ClientId")"
echo -e "$red Working with user pool ID $pool_id, user pool client ID $client_id $reset"

## User sign up

echo -e "$red Starting user signup flow $reset"
awslocal cognito-idp sign-up --client-id "$client_id" --username example_user --password 12345678 --user-attributes Name=email,Value="$USER_EMAIL"

echo -e "$red Confirming user $reset"
awslocal cognito-idp admin-confirm-sign-up --user-pool-id "$pool_id" --username example_user

echo -e "$red Starting auth flow $reset"
awslocal cognito-idp initiate-auth --client-id "$client_id" --auth-flow USER_PASSWORD_AUTH --auth-parameters USERNAME=example_user,PASSWORD=12345678

echo -e "$red Create new user as admin $reset"
awslocal cognito-idp admin-create-user --user-pool-id "$pool_id" --username example_user2

echo -e "$red Attempting to authenticate the not yet verified user - this request should FAIL $reset"
awslocal cognito-idp admin-initiate-auth --user-pool-id "$pool_id" --client-id "$client_id" --auth-flow ADMIN_USER_PASSWORD_AUTH --auth-parameters USERNAME=example_user2,PASSWORD=12345678
echo $?

echo -e "$red Setting password of new user $reset"
awslocal cognito-idp admin-set-user-password --user-pool-id "$pool_id" --username example_user2 --password 12345678 --permanent

echo -e "$red Attempting to authenticate the new user $reset"
awslocal cognito-idp admin-initiate-auth --user-pool-id "$pool_id" --client-id "$client_id" --auth-flow ADMIN_USER_PASSWORD_AUTH --auth-parameters USERNAME=example_user2,PASSWORD=12345678

## "Admin creates the user" with "user initiates auth" workflow

awslocal cognito-idp admin-create-user --user-pool-id "$pool_id" --username example_user3 --temporary-password "ChangeMe"

session=$(awslocal cognito-idp initiate-auth --auth-flow "USER_PASSWORD_AUTH" --auth-parameters USERNAME=example_user3,PASSWORD="ChangeMe" --client-id "$client_id" | jq -r '.Session')

awslocal cognito-idp admin-respond-to-auth-challenge --user-pool-id "$pool_id" --client-id "$client_id" --challenge-responses "NEW_PASSWORD=FinalPassword,USERNAME=example_user3" --challenge-name NEW_PASSWORD_REQUIRED --session "$session"

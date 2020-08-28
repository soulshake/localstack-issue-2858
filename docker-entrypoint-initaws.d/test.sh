#!/bin/bash

apk add jq

red='\033[0;31m'
reset='\033[0m'

[ -z "$FAKE_USERNAME" ] && echo "Need FAKE_USERNAME" && exit 1
[ -z "$FAKE_EMAIL" ] && echo "Need FAKE_EMAIL" && exit 1
[ -z "$FAKE_PASSWORD" ] && echo "Need FAKE_PASSWORD" && exit 1

echo -e "$red Starting user signup flow $reset"

# Create Lambda
awslocal lambda delete-function --function-name test || true
lambda_arn="$(awslocal lambda create-function --function-name test --runtime nodejs12.x --handler cognito-pre-token-generation-lambda-trigger.handler --zip-file fileb:///src/cognito-pre-token-generation-lambda-trigger.zip --role whatever | jq -r .FunctionArn)"

## Create pool and client

lambda_config='{
    "PreSignUp": "'$lambda_arn'",
    "CustomMessage": "'$lambda_arn'",
    "PostConfirmation": "'$lambda_arn'",
    "PreAuthentication": "'$lambda_arn'",
    "PostAuthentication": "'$lambda_arn'",
    "DefineAuthChallenge": "'$lambda_arn'",
    "CreateAuthChallenge": "'$lambda_arn'",
    "VerifyAuthChallengeResponse": "'$lambda_arn'",
    "PreTokenGeneration": "'$lambda_arn'",
    "UserMigration": "'$lambda_arn'"
}'

pool_id=$(awslocal cognito-idp create-user-pool --pool-name test --lambda-config "$lambda_config" | jq -rc ".UserPool.Id")
client_id="$(awslocal cognito-idp create-user-pool-client --user-pool-id "$pool_id" --client-name test-client | jq -rc ".UserPoolClient.ClientId")"
echo -e "$red Working with user pool ID $pool_id, user pool client ID $client_id $reset"

awslocal cognito-idp list-users --user-pool-id "$pool_id"

## User sign up

echo -e "$red Starting user signup flow $reset"
awslocal cognito-idp sign-up --client-id "$client_id" --username "$FAKE_USERNAME" --password "$FAKE_PASSWORD" --user-attributes "Name=email,Value=$FAKE_EMAIL" "Name=sub,Value=abcde-lalala-etc"

echo -e "$red Confirming user $reset"
awslocal cognito-idp admin-confirm-sign-up --user-pool-id "$pool_id" --username "$FAKE_USERNAME"

echo -e "$red Starting auth flow $reset"
awslocal cognito-idp initiate-auth --client-id "$client_id" --auth-flow USER_PASSWORD_AUTH --auth-parameters "USERNAME=$FAKE_USERNAME,PASSWORD=$FAKE_PASSWORD"

# echo -e "$red Create new user as admin $reset"
# awslocal cognito-idp admin-create-user --user-pool-id "$pool_id" --username example_user2

# echo -e "$red Attempting to authenticate the not yet verified user - this request should FAIL $reset"
# awslocal cognito-idp admin-initiate-auth --user-pool-id "$pool_id" --client-id "$client_id" --auth-flow ADMIN_USER_PASSWORD_AUTH --auth-parameters USERNAME=example_user2,PASSWORD=12345678
# echo $?

# echo -e "$red Setting password of new user 2 $reset"
# awslocal cognito-idp admin-set-user-password --user-pool-id "$pool_id" --username example_user2 --password 12345678 --permanent

# echo -e "$red Attempting to authenticate the new user 2 $reset"
# result="$(awslocal cognito-idp admin-initiate-auth --user-pool-id "$pool_id" --client-id "$client_id" --auth-flow ADMIN_USER_PASSWORD_AUTH --auth-parameters USERNAME=example_user2,PASSWORD=12345678)"
# echo "$result"
# refresh_token="$(echo "$result" | jq -r .AuthenticationResult.RefreshToken)"
# echo -e "$red Attempting to initiate REFRESH_TOKEN_AUTH for the new user 2 $reset"
# awslocal cognito-idp initiate-auth --auth-flow REFRESH_TOKEN_AUTH --client-id "$client_id" --auth-parameters "REFRESH_TOKEN=$refresh_token"

# ## "Admin creates the user" with "user initiates auth" workflow

# echo -e "$red Admin creating new user 3 $reset"
# awslocal cognito-idp admin-create-user --user-pool-id "$pool_id" --username example_user3 --temporary-password "ChangeMe"

# echo -e "$red Attempting to authenticate the new user 3 $reset"
# session=$(awslocal cognito-idp initiate-auth --auth-flow "USER_PASSWORD_AUTH" --auth-parameters USERNAME=example_user3,PASSWORD="ChangeMe" --client-id "$client_id" | jq -r '.Session')

# awslocal cognito-idp admin-respond-to-auth-challenge --user-pool-id "$pool_id" --client-id "$client_id" --challenge-responses "NEW_PASSWORD=FinalPassword,USERNAME=example_user3" --challenge-name NEW_PASSWORD_REQUIRED --session "$session"

awslocal cognito-idp list-users --user-pool-id "$pool_id"

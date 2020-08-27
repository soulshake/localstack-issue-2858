// This Lambda function injects Hasura-related claims into Cognito-generated JWTs.
// References:
//   - https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-token-generation.html
//   - https://hasura.io/docs/1.0/graphql/manual/auth/authentication/jwt.html
exports.handler = (event, context, callback) => {
    console.log("______ event ______")
    console.log(JSON.stringify(event))
    event.response = {
        claimsOverrideDetails: {
            claimsToAddOrOverride: {
                "https://hasura.io/jwt/claims": JSON.stringify({
                    "X-Hasura-Allowed-Roles": ["user"],
                    "X-Hasura-Default-Role": "user",
                    "X-Hasura-User-Id": event.request.userAttributes.sub
                })
            }
        }
    }
    callback(null, event)
}

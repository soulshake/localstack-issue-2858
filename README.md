This repo reproduces this issue: https://github.com/localstack/localstack/issues/2858

## Usage

```
git clone git@github.com:soulshake/localstack-issue-2858.git
cd localstack-issue-2858
echo LOCALSTACK_API_KEY=changeme >> .env
docker-compose up -d
docker-compose logs --follow | grep triggerSource
```


Grepping the logs for `triggerSource` shows that none of the [Pre Token Generation Lambda Trigger Sources](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-token-generation.html#user-pool-lambda-pre-token-generation-trigger-source) are triggering Lambdas.

See also:

- [User Pool Lambda Trigger Sources](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html#cognito-user-identity-pools-working-with-aws-lambda-trigger-sources)

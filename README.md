This repo reproduces this issue: https://github.com/localstack/localstack/issues/2858

## Usage

```
git clone git@github.com:soulshake/localstack-issue-2858.git
cd localstack-issue-2858
echo LOCALSTACK_API_KEY=changeme >> .env
docker-compose up -d
```

You can confirm that the created user does have attributes:
```
docker-compose exec localstack bash -c 'awslocal cognito-idp list-users --user-pool-id "$(awslocal cognito-idp list-user-pools --max-results 10 | jq -r .UserPools[0].Id)"'
```

But that they are not provided in the `event.request.userAttributes` passed to the Lambda:

```
docker-compose logs | grep Attributes
```

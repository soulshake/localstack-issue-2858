This repo reproduces this issue: https://github.com/localstack/localstack/issues/2858

## Usage

```
git clone git@github.com:soulshake/localstack-issue-2858.git
cd localstack-issue-2858
echo LOCALSTACK_API_KEY=changeme >> .env
docker-compose up -d
docker-compose logs | grep triggerSource
```

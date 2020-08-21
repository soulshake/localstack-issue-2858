This repo reproduces this issue: https://github.com/localstack/localstack/issues/2858

## Usage

```
echo LOCALSTACK_API_KEY=changeme >> .env
docker-compose up -d
docker-compose logs | grep triggerSource
```

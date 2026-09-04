# Q2 (topics: ConfigMaps, environment variables)

Namespace `athena` has an existing ConfigMap `athena-config` (keys
`APP_MODE`, `LOG_LEVEL`).

Create a Deployment `athena-web`, image `nginx:1-alpine`, **2 replicas**,
container named `web`. The container must:

1. Load **every key** from `athena-config` as environment variables
2. Additionally define its own env var `CACHE_TTL=60`

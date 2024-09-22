# Helm Charts

A collection of Helm Charts

## Run renovate locally
```
docker run \
    -e RENOVATE_CONFIG_FILE="/usr/src/app/renovate.json" \
    -e RENOVATE_TOKEN=$RENOVATE_TOKEN \
    -v $(pwd)/renovate.json:/usr/src/app/renovate.json \
    renovate/renovate --dry-run
```

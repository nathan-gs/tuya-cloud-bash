# Tuya Cloud

A small bash libary to interact with the Tuya Cloud API. 

It also contains a Prometheus Exporter.

| :warning: WARNING                                                |
|:-----------------------------------------------------------------|
| This is HIGHLY EXPERIMENTAL with no ERROR handling at all.       |

## Usage

```sh
TUYA_CLIENT_ID=""
TUYA_SECRET=""
TUYA_BASE_URL="https://openapi.tuyaeu.com"

source tuya.sh

TUYA_ACCESS_TOKEN=$(tuya_get_token $TUYA_CLIENT_ID $TUYA_SECRET "$TUYA_BASE_URL")
tuya $TUYA_CLIENT_ID $TUYA_SECRET "$TUYA_BASE_URL" $TUYA_ACCESS_TOKEN get '/v1.0/iot-01/associated-users/devices?last_row_key='
```

### Prometheus Exporer usage

```sh
TUYA_CLIENT_ID=""
TUYA_SECRET=""
TUYA_BASE_URL="https://openapi.tuyaeu.com"
PROMETHEUS_TEXT_DIR="/var/lib/prometheus-node-exporter/text-files"

mkdir -pm 0775 $PROMETHEUS_TEXT_DIR
F=$PROMETHEUS_TEXT_DIR/tuya-cloud.prom
cat /dev/null > $F.next
source tuya.sh
source tuya_prometheus_exporter.sh
                                
TUYA_ACCESS_TOKEN=$(tuya_get_token $TUYA_CLIENT_ID $TUYA_SECRET "$TUYA_BASE_URL")
# Batch query for the list of associated App user dimension devices
tuya $TUYA_CLIENT_ID $TUYA_SECRET "$TUYA_BASE_URL" $TUYA_ACCESS_TOKEN get '/v1.0/iot-01/associated-users/devices?last_row_key=' get '/v1.0/iot-01/associated-users/devices?last_row_key=' |tuya_parse_batch_query > $F.next
                
mv $F.next $F
```

## Dependencies

- jq
- curl
- awk

## Using inside NixOS

Published as `flake`.


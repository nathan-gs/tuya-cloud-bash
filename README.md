# Tuya Cloud

A small bash libary to interact with the Tuya Cloud API. 

It also contains a Prometheus Exporter.

## Usage

``sh
TUYA_CLIENT_ID=""
TUYA_SECRET=""
TUYA_BASE_URL="https://openapi.tuyaeu.com"

source tuya.sh

TUYA_ACCESS_TOKEN=$(tuya_get_token)
tuya get '/v1.0/iot-01/associated-users/devices?last_row_key=' $TUYA_ACCESS_TOKEN
``
## Dependencies

- jq
- curl

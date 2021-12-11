#!/usr/bin/env bash

#TUYA_CLIENT_ID=""
#TUYA_SECRET=""
#TUYA_BASE_URL="https://openapi.tuyaeu.com"

tuya_get_token() {
  tuya GET /v1.0/token?grant_type=1 | jq -r '.result.access_token'
}


tuya() {
  if [ -z "$TUYA_CLIENT_ID" ]; then
    >&2 echo "TUYA_CLIENT_ID not set"
  fi
  if [ -z "$TUYA_SECRET" ]; then
    >&2 echo "TUYA_SECRET not set"
    exit 1
  fi
  clientId="$TUYA_CLIENT_ID"
  secret="$TUYA_SECRET"
  url="$TUYA_BASE_URL"
  method="${1^^}"
  path="$2"
  accessToken="$3"
  body="$4"
  headers="$5"
  timestamp="$(date '+%s%3N')"

  bodyHash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # empty string

  stringToSign="$method\n$bodyHash\n$headers\n$path"

  signatureToSign="$clientId$accessToken$timestamp$stringToSign"

  signature=$(echo -ne "$signatureToSign" | openssl dgst -sha256 -hmac "$secret" | awk '{print $2}')

  curl --request $method \
    "$url$path" \
    --silent \
    --header "sign_method: HMAC-SHA256" \
    --header "client_id: $clientId" \
    --header "t: $timestamp" \
    --header "access_token: $accessToken" \
    --header "Content-Type: application/json" \
    --header "sign: ${signature^^}"

}

#accessToken=$(tuya_get_token)
#tuya get '/v1.0/iot-01/associated-users/devices?last_row_key=' $accessToken


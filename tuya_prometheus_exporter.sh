#!/usr/bin/env bash

export TUYA_CLIENT_ID
export TUYA_SECRET
export TUYA_BASE_URL

source $(dirname "$0")/tuya.sh

## Parse Batch query for the list of associated App user dimension devices
tuya_parse_batch_query() {

  devices=$(cat - | jq -c '.result.devices[]')

  IFS=$'\n'
  for d in $devices;
    do 
    tuya_device_info $d

    category=$(echo $d | jq -r '.category')
    f="tuya_device_$category"
    if [[ $(type -t $f) == function ]];
    then
      $f $d $category
    else
      tuya_device_generic $d $category
    fi
  done
}

tuya_device_info() {
  d=$1

  filtered=$(echo $d | jq -c 'del(.status) | del (.create_time) | del(.active_time) | del(.online) | del(.time_zone) | del(.update_time)')

  echo -n tuya_device_info"{"
  echo -n $(echo $filtered | jq -rj 'to_entries[] | "\(.key)=\"\(.value)\", "' | sed 's/, $//' )
  echo "} 1"

  echo "tuya_device_online$(tuya_device_info_meta $d) $(echo $d | jq '.online' | sed 's/true/1/' | sed 's/false/0/')"
}

tuya_device_info_meta() {
  d="$1"

  category=$(echo $d | jq -r '.category')
  name=$(echo $d | jq -r '.name')

  echo -n "{category=\"$category\", name=\"$name\"}"
}

tuya_metric() {
  d="$1"
  category="$2"
  name="$3"
  value="$4"

  valueCasted=$(echo $value | sed 's/true/1/' | sed 's/false/0/')
  if [[ "$valueCasted" =~ ^([+-])?[0-9]+([.][0-9]+)?$ ]]; then
    echo "tuya_device_${category}_${name}$(tuya_device_info_meta $d) $valueCasted"
  else
    >&2 echo "tuya_device_${category}_${name}$(tuya_device_info_meta $d) $value is not a number"
  fi
}

tuya_device_generic() {
  d="$1"
  category="$2"

  status=$(echo $d | jq -c '.status[]')

  IFS=$'\n'
  for s in $status;
  do
    code=$(echo $s | jq -r '.code')
    value=$(echo $s | jq -r '.value')
    tuya_metric $d $category $code $value
  done
}

tuya_device_wk() {
  d="$1"

  status=$(echo $d | jq -c '.status[]')

  IFS=$'\n'
  for s in $status;
  do
    code=$(echo $s | jq -r '.code')
    value=$(echo $s | jq -r '.value')

    if [[ "$code" == "temp_current" ]]; then
      temp=$(awk -v n=$value 'BEGIN {printf "%.2f\n", (n/10)}')
      tuya_metric $d wk $code $temp
    else
      if [[ "$code" == "mode" ]]; then
        mode=$(echo $value | sed 's/auto/-1/' | sed 's/manual/-2/' | sed 's/holiday/-3/')
        tuya_metric $d wk $code $mode
      else
        tuya_metric $d wk $code $value
      fi
    fi
  done
}


accessToken=$(tuya_get_token)

# Batch query for the list of associated App user dimension devices
#tuya get '/v1.0/iot-01/associated-users/devices?last_row_key=' $accessToken | jq -c '.result.devices[] '
tuya get '/v1.0/iot-01/associated-users/devices?last_row_key=' $accessToken | tuya_parse_batch_query


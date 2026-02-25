#!/usr/bin/env sh
# shellcheck disable=SC2034
dns_edgeone_info='Tencent Cloud EdgeOne DNS
Site: cloud.tencent.com/product/teo
Docs: See this repo README
Options:
 EDGEONE_SECRET_ID TencentCloud SecretId
 EDGEONE_SECRET_KEY TencentCloud SecretKey
 EDGEONE_TOKEN Temporary session token (optional)
 EDGEONE_ZONE_ID EdgeOne ZoneId (recommended; otherwise best-effort auto-detect)
 EDGEONE_REGION TencentCloud region (optional)
 EDGEONE_TTL TXT record TTL seconds (optional; default 300)
'

EDGEONE_Api="https://teo.tencentcloudapi.com"
EDGEONE_Host="teo.tencentcloudapi.com"
EDGEONE_Service="teo"
EDGEONE_Version="2022-09-01"

########  Public functions #####################

# Usage: dns_edgeone_add _acme-challenge.www.domain.com "txtvalue"
dns_edgeone_add() {
  fulldomain=$1
  txtvalue=$2

  EDGEONE_SECRET_ID="${EDGEONE_SECRET_ID:-$(_readaccountconf_mutable EDGEONE_SECRET_ID)}"
  EDGEONE_SECRET_KEY="${EDGEONE_SECRET_KEY:-$(_readaccountconf_mutable EDGEONE_SECRET_KEY)}"
  EDGEONE_TOKEN="${EDGEONE_TOKEN:-$(_readaccountconf_mutable EDGEONE_TOKEN)}"
  EDGEONE_REGION="${EDGEONE_REGION:-$(_readaccountconf_mutable EDGEONE_REGION)}"
  EDGEONE_TTL="${EDGEONE_TTL:-$(_readaccountconf_mutable EDGEONE_TTL)}"
  EDGEONE_ZONE_ID="${EDGEONE_ZONE_ID:-$(_readdomainconf EDGEONE_ZONE_ID)}"

  if [ -z "$EDGEONE_SECRET_ID" ] || [ -z "$EDGEONE_SECRET_KEY" ]; then
    _err "You didn't specify EdgeOne/TencentCloud credentials."
    _err "Please export EDGEONE_SECRET_ID and EDGEONE_SECRET_KEY."
    return 1
  fi

  EDGEONE_TTL="${EDGEONE_TTL:-300}"
  _saveaccountconf_mutable EDGEONE_SECRET_ID "$EDGEONE_SECRET_ID"
  _saveaccountconf_mutable EDGEONE_SECRET_KEY "$EDGEONE_SECRET_KEY"
  _saveaccountconf_mutable EDGEONE_TOKEN "$EDGEONE_TOKEN"
  _saveaccountconf_mutable EDGEONE_REGION "$EDGEONE_REGION"
  _saveaccountconf_mutable EDGEONE_TTL "$EDGEONE_TTL"

  if ! _edgeone_get_zone "$fulldomain"; then
    return 1
  fi
  _debug EDGEONE_ZONE_ID "$EDGEONE_ZONE_ID"

  _info "Adding TXT record for $fulldomain"
  if _edgeone_create_txt_record "$fulldomain" "$txtvalue" "$EDGEONE_TTL"; then
    _info "Added, OK"
    return 0
  fi

  _info "Create failed, checking if record already exists"
  if _edgeone_txt_record_exists "$fulldomain" "$txtvalue"; then
    _info "Already exists, OK"
    return 0
  fi

  _err "Add txt record error."
  return 1
}

# Usage: dns_edgeone_rm _acme-challenge.www.domain.com "txtvalue"
dns_edgeone_rm() {
  fulldomain=$1
  txtvalue=$2

  EDGEONE_SECRET_ID="${EDGEONE_SECRET_ID:-$(_readaccountconf_mutable EDGEONE_SECRET_ID)}"
  EDGEONE_SECRET_KEY="${EDGEONE_SECRET_KEY:-$(_readaccountconf_mutable EDGEONE_SECRET_KEY)}"
  EDGEONE_TOKEN="${EDGEONE_TOKEN:-$(_readaccountconf_mutable EDGEONE_TOKEN)}"
  EDGEONE_REGION="${EDGEONE_REGION:-$(_readaccountconf_mutable EDGEONE_REGION)}"
  EDGEONE_ZONE_ID="${EDGEONE_ZONE_ID:-$(_readdomainconf EDGEONE_ZONE_ID)}"

  if [ -z "$EDGEONE_SECRET_ID" ] || [ -z "$EDGEONE_SECRET_KEY" ]; then
    _err "You didn't specify EdgeOne/TencentCloud credentials."
    _err "Please export EDGEONE_SECRET_ID and EDGEONE_SECRET_KEY."
    return 1
  fi

  if ! _edgeone_get_zone "$fulldomain"; then
    return 1
  fi
  _debug EDGEONE_ZONE_ID "$EDGEONE_ZONE_ID"

  _info "Removing TXT record for $fulldomain"
  if _edgeone_delete_txt_records "$fulldomain" "$txtvalue"; then
    _info "Removed, OK"
    return 0
  fi
  _err "Remove txt record error."
  return 1
}

####################  Private functions below ##################################

_edgeone_get_zone() {
  fulldomain=$1

  if [ "$EDGEONE_ZONE_ID" ]; then
    _savedomainconf EDGEONE_ZONE_ID "$EDGEONE_ZONE_ID"
    return 0
  fi

  _info "EDGEONE_ZONE_ID not set, trying to auto-detect via DescribeZones"
  if ! _edgeone_detect_zone_id "$fulldomain"; then
    _err "Can not determine ZoneId for $fulldomain."
    _err "Please set EDGEONE_ZONE_ID, e.g.: export EDGEONE_ZONE_ID='zone-xxxxxxxx'."
    return 1
  fi

  _savedomainconf EDGEONE_ZONE_ID "$EDGEONE_ZONE_ID"
  return 0
}

_edgeone_detect_zone_id() {
  fulldomain=$1

  if ! _edgeone_rest "DescribeZones" "{\"Offset\":0,\"Limit\":200}"; then
    return 1
  fi
  if _edgeone_has_error "$response"; then
    _edgeone_log_error "$response"
    return 1
  fi

  best_zone_name=""
  best_zone_id=""

  # Best-effort parsing: look for ZoneName + ZoneId appearing near each other.
  # This assumes Zone objects are mostly flat in the response JSON.
  _zones_lines=$(echo "$response" | tr -d "\n" | sed 's/},{/}\
{/g')
  while IFS= read -r line; do
    zone_name=$(printf "%s" "$line" | _egrep_o "\"ZoneName\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "')
    zone_id=$(printf "%s" "$line" | _egrep_o "\"ZoneId\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "')

    if [ -z "$zone_name" ] || [ -z "$zone_id" ]; then
      continue
    fi

    if [ "$fulldomain" = "$zone_name" ] || _endswith "$fulldomain" ".$zone_name"; then
      if [ -z "$best_zone_name" ] || [ ${#zone_name} -gt ${#best_zone_name} ]; then
        best_zone_name="$zone_name"
        best_zone_id="$zone_id"
      fi
    fi
  done <<EOF
$_zones_lines
EOF

  if [ -z "$best_zone_id" ]; then
    return 1
  fi

  EDGEONE_ZONE_ID="$best_zone_id"
  _info "Detected ZoneId=$EDGEONE_ZONE_ID (ZoneName=$best_zone_name)"
  return 0
}

_edgeone_create_txt_record() {
  fulldomain=$1
  txtvalue=$2
  ttl=$3

  data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"Name\":\"$fulldomain\",\"Type\":\"TXT\",\"Content\":\"$txtvalue\",\"TTL\":$ttl}"
  if ! _edgeone_rest "CreateDnsRecord" "$data"; then
    return 1
  fi
  if _edgeone_has_error "$response"; then
    _edgeone_log_error "$response"
    return 1
  fi
  if _contains "$response" "\"RecordId\""; then
    return 0
  fi
  return 1
}

_edgeone_txt_record_exists() {
  fulldomain=$1
  txtvalue=$2

  if ! _edgeone_describe_txt_records "$fulldomain" "$txtvalue"; then
    return 1
  fi
  record_ids=$(_edgeone_extract_record_ids "$response")
  if [ -n "$record_ids" ]; then
    return 0
  fi
  return 1
}

_edgeone_delete_txt_records() {
  fulldomain=$1
  txtvalue=$2

  if ! _edgeone_describe_txt_records "$fulldomain" "$txtvalue"; then
    return 1
  fi
  record_ids=$(_edgeone_extract_record_ids "$response")
  if [ -z "$record_ids" ]; then
    _info "No matching records, nothing to remove."
    return 0
  fi

  ids_json="["
  for rid in $record_ids; do
    ids_json="$ids_json\"$rid\","
  done
  ids_json="${ids_json%,}]"

  data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"RecordIds\":$ids_json}"
  if ! _edgeone_rest "DeleteDnsRecords" "$data"; then
    return 1
  fi
  if _edgeone_has_error "$response"; then
    _edgeone_log_error "$response"
    return 1
  fi
  return 0
}

_edgeone_describe_txt_records() {
  fulldomain=$1
  txtvalue=$2

  data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"Offset\":0,\"Limit\":1000,\"Filters\":[{\"Fuzzy\":false,\"Name\":\"name\",\"Values\":[\"$fulldomain\"]},{\"Fuzzy\":false,\"Name\":\"type\",\"Values\":[\"TXT\"]},{\"Fuzzy\":false,\"Name\":\"content\",\"Values\":[\"$txtvalue\"]}]}"
  if ! _edgeone_rest "DescribeDnsRecords" "$data"; then
    return 1
  fi
  if _edgeone_has_error "$response"; then
    _edgeone_log_error "$response"
    return 1
  fi
  return 0
}

_edgeone_extract_record_ids() {
  _r="$1"
  printf "%s" "$_r" | _egrep_o "\"RecordId\"[ ]*:[ ]*\"[^\"]*\"" | cut -d : -f 2 | tr -d ' "' | tr '\n' ' ' | tr -s ' '
}

_edgeone_has_error() {
  _r="$1"
  _contains "$_r" "\"Error\"" && _contains "$_r" "\"Response\""
}

_edgeone_log_error() {
  _r="$1"
  code=$(printf "%s" "$_r" | _egrep_o "\"Code\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "')
  msg=$(printf "%s" "$_r" | _egrep_o "\"Message\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "')
  req=$(printf "%s" "$_r" | _egrep_o "\"RequestId\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "')
  _err "EdgeOne API error: Code=$code Message=$msg RequestId=$req"
  _debug2 response "$_r"
}

_edgeone_sha256() {
  printf "%s" "$1" | openssl dgst -sha256 | sed 's/^.* //' | tr -d '\n'
}

_edgeone_hmac_sha256() {
  _key="$1"
  _msg="$2"
  printf "%s" "$_msg" | openssl dgst -sha256 -mac HMAC -macopt key:"$_key" | sed 's/^.* //' | tr -d '\n'
}

_edgeone_hmac_sha256_hexkey() {
  _hexkey="$1"
  _msg="$2"
  printf "%s" "$_msg" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"$_hexkey" | sed 's/^.* //' | tr -d '\n'
}

_edgeone_tc3_authorization() {
  action=$1
  payload=$2
  timestamp=$3
  date=$4

  signed_headers="content-type;host"
  hashed_payload=$(_edgeone_sha256 "$payload")
  canonical_headers=$(printf "content-type:application/json\nhost:%s\n" "$EDGEONE_Host")
  canonical_request=$(printf "POST\n/\n\n%s\n%s\n%s" "$canonical_headers" "$signed_headers" "$hashed_payload")
  hashed_canonical_request=$(_edgeone_sha256 "$canonical_request")
  credential_scope="${date}/${EDGEONE_Service}/tc3_request"
  string_to_sign=$(printf "TC3-HMAC-SHA256\n%s\n%s\n%s" "$timestamp" "$credential_scope" "$hashed_canonical_request")

  secret_date=$(_edgeone_hmac_sha256 "TC3${EDGEONE_SECRET_KEY}" "$date")
  secret_service=$(_edgeone_hmac_sha256_hexkey "$secret_date" "$EDGEONE_Service")
  secret_signing=$(_edgeone_hmac_sha256_hexkey "$secret_service" "tc3_request")
  signature=$(_edgeone_hmac_sha256_hexkey "$secret_signing" "$string_to_sign")

  printf "%s" "TC3-HMAC-SHA256 Credential=${EDGEONE_SECRET_ID}/${credential_scope}, SignedHeaders=${signed_headers}, Signature=${signature}"
}

_edgeone_rest() {
  action=$1
  data=$2

  timestamp=$(date -u +%s)
  date=$(date -u +"%Y-%m-%d")
  authorization=$(_edgeone_tc3_authorization "$action" "$data" "$timestamp" "$date")

  export _H1="X-TC-Action: $action"
  export _H2="X-TC-Version: $EDGEONE_Version"
  export _H3="X-TC-Timestamp: $timestamp"
  export _H4="Authorization: $authorization"

  if [ "$EDGEONE_REGION" ]; then
    export _H5="X-TC-Region: $EDGEONE_REGION"
    if [ "$EDGEONE_TOKEN" ]; then
      export _H6="X-TC-Token: $EDGEONE_TOKEN"
    fi
  else
    if [ "$EDGEONE_TOKEN" ]; then
      export _H5="X-TC-Token: $EDGEONE_TOKEN"
    fi
  fi

  _debug "EdgeOne action=$action"
  _debug2 "data" "$data"
  response="$(_post "$data" "$EDGEONE_Api" "application/json" "POST")"
  if [ "$?" != "0" ]; then
    _err "EdgeOne API request failed: $action"
    return 1
  fi
  _debug2 response "$response"
  return 0
}

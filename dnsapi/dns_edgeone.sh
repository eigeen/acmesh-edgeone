#!/usr/bin/env sh
# shellcheck disable=SC2034
dns_edgeone_info='Tencent Cloud EdgeOne DNS
Site: cloud.tencent.com/product/teo
Docs: See this repo README
Options:
 EDGEONE_SECRET_ID TencentCloud SecretId
 EDGEONE_SECRET_KEY TencentCloud SecretKey
 EDGEONE_TOKEN Temporary session token (optional)
 (Alt) TENCENTCLOUD_SECRET_ID TencentCloud SecretId
 (Alt) TENCENTCLOUD_SECRET_KEY TencentCloud SecretKey
 (Alt) TENCENTCLOUD_TOKEN Temporary session token (optional)
 EDGEONE_ZONE_ID EdgeOne ZoneId (recommended; otherwise best-effort auto-detect)
 EDGEONE_REGION TencentCloud region (optional)
 EDGEONE_TTL TXT record TTL seconds (optional; default 120)
 EDGEONE_CONTENT_TYPE HTTP Content-Type used for signing/request (optional; default "application/json; charset=utf-8")
 EDGEONE_HOST HTTP Host used for signing/request (optional; default "teo.tencentcloudapi.com")
 EDGEONE_SIGN_XTC_ACTION Set to 1 to include x-tc-action in signature (optional; default 0)
'

EDGEONE_DefaultHost="teo.tencentcloudapi.com"
EDGEONE_Service="teo"
EDGEONE_Version="2022-09-01"
EDGEONE_DefaultContentType="application/json; charset=utf-8"

########  Public functions #####################

_edgeone_trim_secret() {
  # Remove surrounding quotes and CR/LF (common when copying from Windows/clipboard).
  # Keep other characters intact.
  printf "%s" "$1" | tr -d '\r\n' | tr -d '"'
}

# Prefer acme.sh built-ins (same style as docs/dns_tencent.sh) for portability across distros/openssl.
_edgeone_sha256() {
  if type _digest >/dev/null 2>&1; then
    printf %b "$@" | _digest sha256 hex
  else
    printf %b "$@" | openssl dgst -sha256 | sed 's/^.* //' | tr -d '\n'
  fi
}

_edgeone_hmac_sha256() {
  k=$1
  shift
  if type _hmac >/dev/null 2>&1 && type _hex_dump >/dev/null 2>&1; then
    hex_key=$(printf %b "$k" | _hex_dump | tr -d ' ')
    printf %b "$@" | _hmac sha256 "$hex_key" hex
  else
    printf %b "$@" | openssl dgst -sha256 -mac hmac -macopt key:"$k" | sed 's/^.* //' | tr -d '\n'
  fi
}

_edgeone_hmac_sha256_hexkey() {
  k=$1
  shift
  if type _hmac >/dev/null 2>&1; then
    printf %b "$@" | _hmac sha256 "$k" hex
  else
    printf %b "$@" | openssl dgst -sha256 -mac hmac -macopt hexkey:"$k" | sed 's/^.* //' | tr -d '\n'
  fi
}

_edgeone_signature_v3() {
  service=$1
  action=$2
  payload=${3:-'{}'}
  timestamp=${4:-$(date -u +%s)}
  content_type=${5:-$EDGEONE_DefaultContentType}

  domain="$EDGEONE_HOST"
  secretId=${EDGEONE_SECRET_ID:-'tencent-cloud-secret-id'}
  secretKey=${EDGEONE_SECRET_KEY:-'tencent-cloud-secret-key'}

  algorithm='TC3-HMAC-SHA256'
  date=$(date -u -d "@$timestamp" +%Y-%m-%d 2>/dev/null)
  [ -z "$date" ] && date=$(date -u -r "$timestamp" +%Y-%m-%d)

  canonicalUri='/'
  canonicalQuery=''

  signedHeaders='content-type;host'
  canonicalHeaders="content-type:$content_type\nhost:$domain\n"
  if _edgeone_should_sign_xtc_action; then
    if type _lower_case >/dev/null 2>&1; then
      action_lc=$(echo "$action" | _lower_case)
    else
      action_lc=$(_edgeone_to_lower "$action")
    fi
    signedHeaders='content-type;host;x-tc-action'
    canonicalHeaders="content-type:$content_type\nhost:$domain\nx-tc-action:$action_lc\n"
  fi

  canonicalRequest="POST\n$canonicalUri\n$canonicalQuery\n$canonicalHeaders\n$signedHeaders\n$(_edgeone_sha256 "$payload")"

  credentialScope="$date/$service/tc3_request"
  stringToSign="$algorithm\n$timestamp\n$credentialScope\n$(_edgeone_sha256 "$canonicalRequest")"

  secretDate=$(_edgeone_hmac_sha256 "TC3$secretKey" "$date")
  secretService=$(_edgeone_hmac_sha256_hexkey "$secretDate" "$service")
  secretSigning=$(_edgeone_hmac_sha256_hexkey "$secretService" 'tc3_request')
  signature=$(_edgeone_hmac_sha256_hexkey "$secretSigning" "$stringToSign")

  echo "$algorithm Credential=$secretId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
}

# Usage: dns_edgeone_add _acme-challenge.www.domain.com "txtvalue"
dns_edgeone_add() {
  fulldomain=$1
  txtvalue=$2

  EDGEONE_SECRET_ID="${EDGEONE_SECRET_ID:-$(_readaccountconf_mutable EDGEONE_SECRET_ID)}"
  EDGEONE_SECRET_KEY="${EDGEONE_SECRET_KEY:-$(_readaccountconf_mutable EDGEONE_SECRET_KEY)}"
  EDGEONE_TOKEN="${EDGEONE_TOKEN:-$(_readaccountconf_mutable EDGEONE_TOKEN)}"
  EDGEONE_REGION="${EDGEONE_REGION:-$(_readaccountconf_mutable EDGEONE_REGION)}"
  EDGEONE_TTL="${EDGEONE_TTL:-$(_readaccountconf_mutable EDGEONE_TTL)}"
  EDGEONE_CONTENT_TYPE="${EDGEONE_CONTENT_TYPE:-$(_readaccountconf_mutable EDGEONE_CONTENT_TYPE)}"
  EDGEONE_HOST="${EDGEONE_HOST:-$(_readaccountconf_mutable EDGEONE_HOST)}"
  EDGEONE_TXT_OVERWRITE="${EDGEONE_TXT_OVERWRITE:-$(_readaccountconf_mutable EDGEONE_TXT_OVERWRITE)}"
  EDGEONE_ZONE_ID="${EDGEONE_ZONE_ID:-$(_readdomainconf EDGEONE_ZONE_ID)}"

  EDGEONE_SECRET_ID="${EDGEONE_SECRET_ID:-$TENCENTCLOUD_SECRET_ID}"
  EDGEONE_SECRET_KEY="${EDGEONE_SECRET_KEY:-$TENCENTCLOUD_SECRET_KEY}"
  EDGEONE_TOKEN="${EDGEONE_TOKEN:-${TENCENTCLOUD_TOKEN:-$TENCENTCLOUD_SESSION_TOKEN}}"

  EDGEONE_SECRET_ID=$(_edgeone_trim_secret "$EDGEONE_SECRET_ID")
  EDGEONE_SECRET_KEY=$(_edgeone_trim_secret "$EDGEONE_SECRET_KEY")
  EDGEONE_TOKEN=$(_edgeone_trim_secret "$EDGEONE_TOKEN")

  if [ -z "$EDGEONE_SECRET_ID" ] || [ -z "$EDGEONE_SECRET_KEY" ]; then
    _err "You didn't specify EdgeOne/TencentCloud credentials."
    _err "Please export EDGEONE_SECRET_ID and EDGEONE_SECRET_KEY."
    return 1
  fi

  EDGEONE_TTL="${EDGEONE_TTL:-120}"
  EDGEONE_CONTENT_TYPE="${EDGEONE_CONTENT_TYPE:-$EDGEONE_DefaultContentType}"
  EDGEONE_HOST="${EDGEONE_HOST:-$EDGEONE_DefaultHost}"
  EDGEONE_TXT_OVERWRITE="${EDGEONE_TXT_OVERWRITE:-1}"
  _saveaccountconf_mutable EDGEONE_SECRET_ID "$EDGEONE_SECRET_ID"
  _saveaccountconf_mutable EDGEONE_SECRET_KEY "$EDGEONE_SECRET_KEY"
  _saveaccountconf_mutable EDGEONE_TOKEN "$EDGEONE_TOKEN"
  _saveaccountconf_mutable EDGEONE_REGION "$EDGEONE_REGION"
  _saveaccountconf_mutable EDGEONE_TTL "$EDGEONE_TTL"
  _saveaccountconf_mutable EDGEONE_CONTENT_TYPE "$EDGEONE_CONTENT_TYPE"
  _saveaccountconf_mutable EDGEONE_HOST "$EDGEONE_HOST"
  _saveaccountconf_mutable EDGEONE_TXT_OVERWRITE "$EDGEONE_TXT_OVERWRITE"

  if ! _edgeone_get_zone "$fulldomain"; then
    return 1
  fi
  _debug EDGEONE_ZONE_ID "$EDGEONE_ZONE_ID"

  _info "Adding TXT record for $fulldomain"
  if _edgeone_upsert_txt_record "$fulldomain" "$txtvalue" "$EDGEONE_TTL"; then
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
  EDGEONE_CONTENT_TYPE="${EDGEONE_CONTENT_TYPE:-$(_readaccountconf_mutable EDGEONE_CONTENT_TYPE)}"
  EDGEONE_HOST="${EDGEONE_HOST:-$(_readaccountconf_mutable EDGEONE_HOST)}"
  EDGEONE_ZONE_ID="${EDGEONE_ZONE_ID:-$(_readdomainconf EDGEONE_ZONE_ID)}"

  EDGEONE_SECRET_ID="${EDGEONE_SECRET_ID:-$TENCENTCLOUD_SECRET_ID}"
  EDGEONE_SECRET_KEY="${EDGEONE_SECRET_KEY:-$TENCENTCLOUD_SECRET_KEY}"
  EDGEONE_TOKEN="${EDGEONE_TOKEN:-${TENCENTCLOUD_TOKEN:-$TENCENTCLOUD_SESSION_TOKEN}}"

  EDGEONE_SECRET_ID=$(_edgeone_trim_secret "$EDGEONE_SECRET_ID")
  EDGEONE_SECRET_KEY=$(_edgeone_trim_secret "$EDGEONE_SECRET_KEY")
  EDGEONE_TOKEN=$(_edgeone_trim_secret "$EDGEONE_TOKEN")

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
  _err "EdgeOne unexpected CreateDnsRecord response: $response"
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

_edgeone_record_id_conf_key() {
  fulldomain=$1
  txtvalue=$2
  _k=$(_edgeone_sha256 "$(printf "%s|%s|%s" "$EDGEONE_ZONE_ID" "$fulldomain" "$txtvalue")")
  printf "%s" "EDGEONE_RecordId_${_k}"
}

_edgeone_extract_first_record_id() {
  _r="$1"
  printf "%s" "$_r" | _egrep_o "\"RecordId\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "'
}

_edgeone_response_error_code() {
  _r="$1"
  printf "%s" "$_r" | _egrep_o "\"Code\"[ ]*:[ ]*\"[^\"]*\"" | _head_n 1 | cut -d : -f 2 | tr -d ' "'
}

_edgeone_upsert_txt_record() {
  fulldomain=$1
  txtvalue=$2
  ttl=$3

  if _edgeone_create_txt_record "$fulldomain" "$txtvalue" "$ttl"; then
    rid=$(_edgeone_extract_first_record_id "$response")
    if [ "$rid" ]; then
      _k=$(_edgeone_record_id_conf_key "$fulldomain" "$txtvalue")
      _savedomainconf "$_k" "$rid"
    fi
    _info "Added, OK"
    return 0
  fi

  # If Create failed due to CNAME conflict, there's nothing to overwrite: user must remove/disable the CNAME.
  err_code=$(_edgeone_response_error_code "$response")
  if [ "$err_code" = "InvalidParameterValue.ConflictWithRecord" ]; then
    _err "EdgeOne TXT record conflicts with an existing CNAME for $fulldomain."
    _err "Please delete/disable the CNAME record at $fulldomain and retry, or use ACME DNS alias (CNAME delegation) to another zone."
    return 1
  fi

  if [ "${EDGEONE_TXT_OVERWRITE:-1}" = "0" ]; then
    _err "Create failed and EDGEONE_TXT_OVERWRITE=0, not attempting to detect/overwrite existing TXT record(s)."
    return 1
  fi

  _info "Create failed, checking existing TXT records"
  if ! _edgeone_describe_txt_records_by_name "$fulldomain"; then
    return 1
  fi

  # If already present, OK.
  _resp_compact=$(echo "$response" | tr -d ' ')
  if _contains "$_resp_compact" "\"Content\":\"$txtvalue\""; then
    _info "Already exists, OK"
    return 0
  fi

  record_ids=$(_edgeone_extract_record_ids "$response")
  if [ -z "$record_ids" ]; then
    _err "No existing TXT record found to overwrite."
    return 1
  fi

  set -- $record_ids
  rid=$1
  _info "Overwriting TXT record (RecordId=$rid)"
  if _edgeone_modify_record_content "$rid" "$txtvalue"; then
    _info "Overwritten, OK"
    return 0
  fi
  return 1
}

_edgeone_delete_txt_records() {
  fulldomain=$1
  txtvalue=$2

  # Prefer deleting by RecordId saved at add-time (avoids requiring Describe permission).
  _k=$(_edgeone_record_id_conf_key "$fulldomain" "$txtvalue")
  saved_rid=$(_readdomainconf "$_k")
  if [ "$saved_rid" ]; then
    data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"RecordIds\":[\"$saved_rid\"]}"
    if _edgeone_rest "DeleteDnsRecords" "$data"; then
      if _edgeone_has_error "$response"; then
        _edgeone_log_error "$response"
        return 1
      fi
      _cleardomainconf "$_k"
      return 0
    fi
    return 1
  fi

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

_edgeone_describe_txt_records_by_name() {
  fulldomain=$1

  data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"Offset\":0,\"Limit\":1000,\"Filters\":[{\"Fuzzy\":false,\"Name\":\"name\",\"Values\":[\"$fulldomain\"]},{\"Fuzzy\":false,\"Name\":\"type\",\"Values\":[\"TXT\"]}]}"
  if ! _edgeone_rest "DescribeDnsRecords" "$data"; then
    return 1
  fi
  if _edgeone_has_error "$response"; then
    _edgeone_log_error "$response"
    return 1
  fi
  return 0
}

_edgeone_modify_record_content() {
  record_id=$1
  txtvalue=$2

  data="{\"ZoneId\":\"$EDGEONE_ZONE_ID\",\"DnsRecords\":[{\"RecordId\":\"$record_id\",\"Content\":\"$txtvalue\"}]}"
  if ! _edgeone_rest "ModifyDnsRecords" "$data"; then
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

_edgeone_to_lower() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

_edgeone_should_sign_xtc_action() {
  [ "${EDGEONE_SIGN_XTC_ACTION:-0}" = "1" ]
}

_edgeone_tc3_authorization() {
  action=$1
  payload=$2
  timestamp=$3
  date=$4
  content_type=$5

  token=$(_edgeone_signature_v3 "$EDGEONE_Service" "$action" "$payload" "$timestamp" "$content_type")
  printf "%s" "$token"
}

_edgeone_debug_sign() {
  action=$1
  payload=$2
  timestamp=$3
  date=$4
  content_type=$5

  if [ "${EDGEONE_DEBUG_SIGN:-0}" != "1" ]; then
    return 0
  fi

  # Reconstruct the same canonical request used by signature_v3() for easier troubleshooting.
  signed_headers='content-type;host'
  canonical_headers="content-type:$content_type\nhost:$EDGEONE_HOST\n"
  if _edgeone_should_sign_xtc_action; then
    if type _lower_case >/dev/null 2>&1; then
      action_lc=$(echo "$action" | _lower_case)
    else
      action_lc=$(_edgeone_to_lower "$action")
    fi
    signed_headers='content-type;host;x-tc-action'
    canonical_headers="content-type:$content_type\nhost:$EDGEONE_HOST\nx-tc-action:$action_lc\n"
  fi

  canonical_request="POST\n/\n\n$canonical_headers\n$signed_headers\n$(_edgeone_sha256 "$payload")"
  credential_scope="${date}/${EDGEONE_Service}/tc3_request"
  string_to_sign="TC3-HMAC-SHA256\n$timestamp\n$credential_scope\n$(_edgeone_sha256 "$canonical_request")"

  secret_date=$(_edgeone_hmac_sha256 "TC3${EDGEONE_SECRET_KEY}" "$date")
  secret_service=$(_edgeone_hmac_sha256_hexkey "$secret_date" "$EDGEONE_Service")
  secret_signing=$(_edgeone_hmac_sha256_hexkey "$secret_service" "tc3_request")
  signature=$(_edgeone_hmac_sha256_hexkey "$secret_signing" "$string_to_sign")

  _debug "EdgeOne canonical_request" "$canonical_request"
  _debug "EdgeOne string_to_sign" "$string_to_sign"
  _debug "EdgeOne signature" "$signature"
}

_edgeone_rest() {
  action=$1
  data=$2

  EDGEONE_HOST="${EDGEONE_HOST:-$EDGEONE_DefaultHost}"
  EDGEONE_CONTENT_TYPE="${EDGEONE_CONTENT_TYPE:-$EDGEONE_DefaultContentType}"
  timestamp=$(date -u +%s)
  date=$(date -u +"%Y-%m-%d")
  authorization=$(_edgeone_tc3_authorization "$action" "$data" "$timestamp" "$date" "$EDGEONE_CONTENT_TYPE")
  _edgeone_debug_sign "$action" "$data" "$timestamp" "$date" "$EDGEONE_CONTENT_TYPE"

  _debug "EdgeOne action=$action"
  _debug "EdgeOne content-type" "$EDGEONE_CONTENT_TYPE"
  _debug2 "data" "$data"
  if [ "$EDGEONE_TOKEN" ]; then
    # Temporary credentials require X-TC-Token.
    # Keep within _H1.._H5 for compatibility with older acme.sh.
    _H1="X-TC-Action: $action"
    _H2="X-TC-Version: $EDGEONE_Version"
    _H3="X-TC-Timestamp: $timestamp"
    _H4="Authorization: $authorization"
    _H5="X-TC-Token: $EDGEONE_TOKEN"
  else
    # Explicitly set Host to avoid HTTP/2 authority/host edge cases during signature validation.
    _H1="Host: $EDGEONE_HOST"
    _H2="X-TC-Action: $action"
    _H3="X-TC-Version: $EDGEONE_Version"
    _H4="X-TC-Timestamp: $timestamp"
    _H5="Authorization: $authorization"
  fi

  response="$(_post "$data" "https://$EDGEONE_HOST" "" "POST" "$EDGEONE_CONTENT_TYPE")"
  if [ "$?" != "0" ]; then
    _err "EdgeOne API request failed: $action"
    return 1
  fi
  _debug2 response "$response"
  return 0
}

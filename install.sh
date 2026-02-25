#!/usr/bin/env sh
set -eu

script_dir=$(
  CDPATH= cd "$(dirname "$0")" >/dev/null 2>&1
  pwd
)

acme_home="${1:-${ACME_HOME:-${ACME_SH_HOME:-$HOME/.acme.sh}}}"
acme_home=$(printf "%s" "$acme_home" | sed 's:/*$::')

if [ ! -f "$acme_home/acme.sh" ]; then
  echo "ERROR: acme.sh not found at: $acme_home/acme.sh" >&2
  echo "Hint: pass acme home as first arg, e.g.: ./install.sh ~/.acme.sh" >&2
  exit 1
fi

download() {
  url=$1
  out=$2
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
    return $?
  fi
  echo "ERROR: need curl or wget to download: $url" >&2
  return 1
}

module_src="$script_dir/dnsapi/dns_edgeone.sh"
tmp_module=""
if [ ! -f "$module_src" ]; then
  repo_raw_base="${EDGEONE_REPO_RAW_BASE:-https://raw.githubusercontent.com/eigeen/acmesh-edgeone/main}"
  module_url="${EDGEONE_DNSAPI_URL:-$repo_raw_base/dnsapi/dns_edgeone.sh}"
  tmp_module="$(mktemp -t dns_edgeone.XXXXXX)"
  trap 'rm -f "$tmp_module"' EXIT
  echo "Downloading: $module_url"
  download "$module_url" "$tmp_module"
  if [ ! -s "$tmp_module" ]; then
    echo "ERROR: downloaded module is empty: $module_url" >&2
    exit 1
  fi
  module_src="$tmp_module"
fi

mkdir -p "$acme_home/dnsapi"
cp "$module_src" "$acme_home/dnsapi/dns_edgeone.sh"
chmod 755 "$acme_home/dnsapi/dns_edgeone.sh"

echo "Installed: $acme_home/dnsapi/dns_edgeone.sh"
echo "Usage:"
echo "  export EDGEONE_SECRET_ID='...'"
echo "  export EDGEONE_SECRET_KEY='...'"
echo "  export EDGEONE_ZONE_ID='zone-xxxxxxxx'"
echo "  acme.sh --issue -d example.com --dns dns_edgeone"

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

mkdir -p "$acme_home/dnsapi"
cp "$script_dir/dnsapi/dns_edgeone.sh" "$acme_home/dnsapi/dns_edgeone.sh"
chmod 755 "$acme_home/dnsapi/dns_edgeone.sh"

echo "Installed: $acme_home/dnsapi/dns_edgeone.sh"
echo "Usage:"
echo "  export EDGEONE_SECRET_ID='...'"
echo "  export EDGEONE_SECRET_KEY='...'"
echo "  export EDGEONE_ZONE_ID='zone-xxxxxxxx'"
echo "  acme.sh --issue -d example.com --dns dns_edgeone"

#!/usr/bin/env sh
set -eu

acme_home="${1:-${ACME_HOME:-${ACME_SH_HOME:-$HOME/.acme.sh}}}"
acme_home=$(printf "%s" "$acme_home" | sed 's:/*$::')

target="$acme_home/dnsapi/dns_edgeone.sh"
if [ -f "$target" ]; then
  rm -f "$target"
  echo "Removed: $target"
else
  echo "Not found: $target"
fi


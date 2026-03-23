#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -n "${AMPEL:-}" ]; then
  AMPEL="$AMPEL"
elif command -v ampel &>/dev/null; then
  AMPEL="ampel"
else
  AMPEL="../carabiner/ampel/ampel"
fi

mkdir -p output/medium/ampel/ 2>/dev/null

"$AMPEL" verify "$(crane digest ghcr.io/puerco/mild-to-wild-samples)" \
    --collector oci:ghcr.io/puerco/mild-to-wild-samples \
    --policy 2-medium/ampel/policy.hjson \
    --attestation output/mild/ampel/base.vsa.json \
    --attest-format vsa \
    --attest-results=true \
    --results-path=output/medium/ampel/image.vsa.json
    

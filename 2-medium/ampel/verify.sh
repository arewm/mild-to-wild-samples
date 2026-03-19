#!/usr/bin/env bash

set -euo pipefail

if [ -n "${AMPEL:-}" ]; then
  AMPEL="$AMPEL"
elif command -v ampel &>/dev/null; then
  AMPEL="ampel"
else
  AMPEL="../carabiner/ampel/ampel"
fi

mkdir -p output 2>/dev/null

"$AMPEL" verify "$(crane manifest ghcr.io/puerco/mild-to-wild-samples | jq -r '.annotations["org.opencontainers.image.base.digest"]')" \
   --policy 1-mild/ampel/policy.hjson \
   --collector coci:registry.access.redhat.com/ubi10/ubi-minimal:latest \
   --context 'buildPoint:git+https://gitlab.com/redhat/rhel/containers/ubi10-minimal.git' \
   --attest-format vsa \
   --attest-results=true \
   --results-path=output/base.vsa.json

"$AMPEL" verify "$(crane digest ghcr.io/puerco/mild-to-wild-samples)" \
    --collector oci:ghcr.io/puerco/mild-to-wild-samples \
    --policy 2-medium/ampel/policy.hjson \
    --attestation output/base.vsa.json \
    --attest-format vsa \
    --attest-results=true \
    --results-path=output/image.vsa.json
    

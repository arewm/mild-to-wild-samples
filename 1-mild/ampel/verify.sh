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

mkdir -p output/mild/ampel 2>/dev/null

"$AMPEL" verify "$(crane manifest ghcr.io/puerco/mild-to-wild-samples | jq -r '.annotations["org.opencontainers.image.base.digest"]')" \
   --policy 1-mild/ampel/policy.hjson \
   --collector coci:registry.access.redhat.com/ubi10/ubi-minimal@sha256:734d6c22b80cdf9bd21c6b13d3475cf04d46f131cdb4b32a88cc96c40c6feab1 \
 \
   --context 'buildPoint:git+https://gitlab.com/redhat/rhel/containers/ubi10-minimal.git' \
   --attest-format vsa \
   --attest-results=true \
   --results-path=output/mild/ampel/base.vsa.json

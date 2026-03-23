#!/usr/bin/env bash

set -euo pipefail
set -x

IMAGE="quay.io/arewm/mild-to-wild-samples:build-20260314-021538"


if [ -n "${AMPEL:-}" ]; then
  AMPEL="$AMPEL"
elif command -v ampel &>/dev/null; then
  AMPEL="ampel"
else
  AMPEL="../carabiner/ampel/ampel"
fi

mkdir -p output/wild/ampel/ 2>/dev/null

echo ""
echo "Dowloading trusted tasks..."

# Download required tasks list
curl -sSfL -o /tmp/required_tasks.yml \
  "https://raw.githubusercontent.com/arewm/mild-to-wild-samples/main/3-wild/conforma/data/trusted-tasks.yaml"

echo ""
echo "Verifying base image (to VSA)"

"$AMPEL" verify "$(crane manifest ${IMAGE} | jq -r '.annotations["org.opencontainers.image.base.digest"]')" \
   --policy 1-mild/ampel/policy.hjson \
   --collector coci:registry.access.redhat.com/ubi10/ubi-minimal@$(crane manifest ${IMAGE} | jq -r '.annotations["org.opencontainers.image.base.digest"]') \
   --context 'buildPoint:git+https://gitlab.com/redhat/rhel/containers/ubi10-minimal.git' \
   --attest-format vsa \
   --attest-results=true \
   --results-path=output/wild/ampel/tekton-base.vsa.json

echo ""
echo "Verifying image and trusted tasks..."

"$AMPEL" verify "$(crane digest ${IMAGE})" \
    --collector coci:${IMAGE} \
    --policy 3-wild/ampel/policy.hjson \
    --attestation output/wild/ampel/tekton-base.vsa.json \
    --context "baseDigest:$(crane manifest ${IMAGE} | jq -r '.annotations["org.opencontainers.image.base.digest"]')" \
    --context-yaml @/tmp/required_tasks.yml \
    --attest-format vsa \
    --attest-results=true \
    --results-path=output/wild/ampel/tekton-image.vsa.json
    

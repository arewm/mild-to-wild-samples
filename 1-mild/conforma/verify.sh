#!/usr/bin/env bash
# Mild: Verify the base image's release signature and SLSA provenance with Conforma.

set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-registry.access.redhat.com/ubi10/ubi-minimal:latest}"

mkdir -p output/mild/conforma

echo ""
echo "=== Mild: Verifying base image ==="
echo "Image: ${BASE_IMAGE}"

echo ""
echo "--- Step 1: Verify release signature"
echo "    Key: 1-mild/conforma/cosign-release.pub"
ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"'"${BASE_IMAGE}"'"}]}' \
  --public-key 1-mild/conforma/cosign-release.pub \
  --ignore-rekor \
  --policy '{"sources":[]}' \
  --show-successes \
  --output 'text?show-successes=false' \
  --output json=output/mild/conforma/signature-report.json
jq . output/mild/conforma/signature-report.json > output/mild/conforma/signature-report.json.tmp \
  && mv output/mild/conforma/signature-report.json.tmp output/mild/conforma/signature-report.json

echo ""
echo "--- Step 2: Verify provenance"
echo "    Policy: 1-mild/conforma/policy.yaml"
echo "    Key: 1-mild/conforma/cosign-provenance.pub"
ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"'"${BASE_IMAGE}"'"}]}' \
  --policy 1-mild/conforma/policy.yaml \
  --public-key 1-mild/conforma/cosign-provenance.pub \
  --ignore-rekor \
  --skip-image-sig-check \
  --show-successes \
  --output 'text?show-successes=false' \
  --output json=output/mild/conforma/provenance-report.json
jq . output/mild/conforma/provenance-report.json > output/mild/conforma/provenance-report.json.tmp \
  && mv output/mild/conforma/provenance-report.json.tmp output/mild/conforma/provenance-report.json

echo ""
echo "=== Output files ==="
echo "  output/mild/conforma/signature-report.json  — image signature verification result"
echo "  output/mild/conforma/provenance-report.json — SLSA provenance policy evaluation"

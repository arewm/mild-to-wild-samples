#!/usr/bin/env bash
# Wild: Verify base image + Tekton-built image with trusted task checks,
# produce a VSA at SLSA Build Level 2 (untrusted tasks) or Level 3 (all trusted).

set -euo pipefail

BUILT_IMAGE="${BUILT_IMAGE:-quay.io/arewm/mild-to-wild-samples:build-20260319-164911}"

echo ""
echo "=== Wild: Verifying image with trusted task checks ==="
echo "Image: ${BUILT_IMAGE}"
echo ""
echo "Policies:"
echo "  Base image:  1-mild/conforma/policy.yaml"
echo "  Built image: 3-wild/conforma/policy.yaml"
echo "  Trusted tasks: 3-wild/conforma/data/trusted-tasks.yaml"

scripts/generate-vsa.sh \
  --image "${BUILT_IMAGE}" \
  --policy 3-wild/conforma/policy.yaml \
  --public-key provenance.pub \
  --ignore-rekor \
  --base-image-policy 1-mild/conforma/policy.yaml \
  --base-image-key 1-mild/conforma/cosign-provenance.pub \
  --base-image-release-key 1-mild/conforma/cosign-release.pub \
  --report-dir output/wild/conforma \
  --vsa-signing-key vsa.key \
  --no-attach \
  --output output/wild/conforma/image.vsa.json

echo ""
echo "=== Output files ==="
echo "  output/wild/conforma/base-report.json  — base image provenance policy evaluation"
echo "  output/wild/conforma/built-report.json — built image provenance + trusted task evaluation"
echo "  output/wild/conforma/image.vsa.json    — SLSA Verification Summary Attestation (L2 or L3)"

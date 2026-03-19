#!/usr/bin/env bash
# Medium: Verify base image + built image, produce a VSA at SLSA Build Level 2.
#
# Supports both GitHub Actions (keyless) and Tekton Chains (key-based) builds.
# Set PUBLIC_KEY to switch to key-based verification:
#   PUBLIC_KEY=provenance.pub BUILT_IMAGE=quay.io/... ./2-medium/conforma/verify.sh

set -euo pipefail

BUILT_IMAGE="${BUILT_IMAGE:-ghcr.io/arewm/mild-to-wild-samples}"

echo ""
echo "=== Medium: Verifying image and producing VSA ==="
echo "Image: ${BUILT_IMAGE}"
echo ""
echo "Policies:"
echo "  Base image:  1-mild/conforma/policy.yaml"
echo "  Built image: 2-medium/conforma/policy.yaml"

BUILT_IMAGE_ARGS=()
if [[ -n "${PUBLIC_KEY:-}" ]]; then
  echo "  Mode: key-based (Tekton Chains)"
  BUILT_IMAGE_ARGS+=(--public-key "$PUBLIC_KEY" --ignore-rekor)
else
  echo "  Mode: keyless (GitHub Actions)"
  BUILT_IMAGE_ARGS+=(
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
    --certificate-identity "https://github.com/arewm/mild-to-wild-samples/.github/workflows/build-push.yaml@refs/heads/main"
    --rekor-url https://rekor.sigstore.dev
  )
fi

scripts/generate-vsa.sh \
  --image "${BUILT_IMAGE}" \
  --policy 2-medium/conforma/policy.yaml \
  "${BUILT_IMAGE_ARGS[@]}" \
  --base-image-policy 1-mild/conforma/policy.yaml \
  --base-image-key 1-mild/conforma/cosign-provenance.pub \
  --base-image-release-key 1-mild/conforma/cosign-release.pub \
  --report-dir output/medium/conforma \
  --vsa-signing-key vsa.key \
  --no-attach \
  --output output/medium/conforma/image.vsa.json

echo ""
echo "=== Output files ==="
echo "  output/medium/conforma/base-report.json  — base image provenance policy evaluation"
echo "  output/medium/conforma/built-report.json — built image provenance policy evaluation"
echo "  output/medium/conforma/image.vsa.json    — SLSA Verification Summary Attestation (L2)"

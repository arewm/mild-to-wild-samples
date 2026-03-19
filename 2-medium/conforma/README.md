# Medium: Conforma

The medium level verifies both the base image and the built image, running the same SLSA provenance checks on each. It then produces a VSA at SLSA Build Level 2, capturing the verification outcome so downstream consumers can enforce policy without re-running the checks.

The policy supports both Tekton Chains and GitHub Actions builds. Two passes are needed because the base image and built image have different signing keys and builder configurations.

For GitHub Actions builds, the medium policy adds `github_certificate` rules that validate the Sigstore Fulcio certificate properties — verifying the workflow ran from an allowed repository and ref. The `gh_workflow_extensions` rule produces warnings because the workflow re-signs the attestation with `cosign attest`, which obtains a Fulcio certificate with the standard OIDC identity but without the GitHub-specific OID extensions that `slsa-github-generator` would populate. These warnings are expected and do not affect the verification outcome; the deny rules (`gh_workflow_repository`, `gh_workflow_ref`) still enforce the allowed values via the certificate's subject identity.

## Usage

Run the demo script from the repo root:

```bash
# GitHub Actions (default)
./2-medium/conforma/verify.sh

# Tekton Chains
PUBLIC_KEY=provenance.pub BUILT_IMAGE=quay.io/arewm/mild-to-wild-samples:build-20260314-021538 \
  ./2-medium/conforma/verify.sh
```

The script detects whether `PUBLIC_KEY` is set to choose between key-based (Tekton Chains) and keyless (GitHub Actions) verification.

### Manual steps

Pass 1 — Verify the base image release signature and provenance (same as mild):

```bash
ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"<BASE_IMAGE_REF>"}]}' \
  --public-key 1-mild/conforma/cosign-release.pub \
  --ignore-rekor \
  --policy '{"sources":[]}'

ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"<BASE_IMAGE_REF>"}]}' \
  --policy 1-mild/conforma/policy.yaml \
  --public-key 1-mild/conforma/cosign-provenance.pub \
  --ignore-rekor \
  --skip-image-sig-check
```

Pass 2 — Verify the built image. For GitHub Actions (keyless):

```bash
ec validate image \
  --images '{"components":[{"name":"built-image","containerImage":"<BUILT_IMAGE_REF>"}]}' \
  --policy 2-medium/conforma/policy.yaml \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity '<WORKFLOW_IDENTITY>' \
  --rekor-url https://rekor.sigstore.dev
```

For Tekton Chains (key-based):

```bash
ec validate image \
  --images '{"components":[{"name":"built-image","containerImage":"<BUILT_IMAGE_REF>"}]}' \
  --policy 2-medium/conforma/policy.yaml \
  --public-key 3-wild/conforma/cosign-chains.pub \
  --ignore-rekor
```

## VSA Generation

The `scripts/generate-vsa.sh` script runs both passes and generates a SLSA VSA. For GitHub Actions (keyless):

```bash
scripts/generate-vsa.sh \
  --image <BUILT_IMAGE_REF> \
  --policy 2-medium/conforma/policy.yaml \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity '<WORKFLOW_IDENTITY>' \
  --rekor-url https://rekor.sigstore.dev \
  --base-image-policy 1-mild/conforma/policy.yaml \
  --base-image-key 1-mild/conforma/cosign-provenance.pub \
  --base-image-release-key 1-mild/conforma/cosign-release.pub \
  --vsa-signing-key vsa.key
```

For Tekton Chains (key-based):

```bash
scripts/generate-vsa.sh \
  --image <BUILT_IMAGE_REF> \
  --policy 2-medium/conforma/policy.yaml \
  --public-key provenance.pub \
  --ignore-rekor \
  --base-image-policy 1-mild/conforma/policy.yaml \
  --base-image-key 1-mild/conforma/cosign-provenance.pub \
  --base-image-release-key 1-mild/conforma/cosign-release.pub \
  --vsa-signing-key vsa.key
```

Use `--no-attach` to produce the VSA predicate without pushing it to the registry.

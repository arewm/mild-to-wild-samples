# Mild: Conforma

Verifies the base image (e.g. UBI) used in the Containerfile. Two custom rules check that SLSA provenance is present and that the buildType matches an allowlist. The remaining checks — builder identity, source materials, and external parameters — come from the upstream Conforma policy library (`slsa_build_build_service`, `slsa_source_version_controlled`, `external_parameters`).

The base image uses two different signing keys, so verification requires two `ec validate image` calls:

- **`cosign-release.pub`** — Red Hat's [release3 key](https://access.redhat.com/security/team/key/#702D426D) for the image signature
- **`cosign-provenance.pub`** — the Chains key that signed the provenance attestation

## Usage

Run the demo script from the repo root:

```bash
./1-mild/conforma/verify.sh
```

Or run the steps manually:

Step 1 — Verify the release signature (no policy rules, just signature check):

```bash
ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"<BASE_IMAGE_REF>"}]}' \
  --public-key 1-mild/conforma/cosign-release.pub \
  --ignore-rekor \
  --policy '{"sources":[]}'
```

Step 2 — Verify provenance against policy:

```bash
ec validate image \
  --images '{"components":[{"name":"base-image","containerImage":"<BASE_IMAGE_REF>"}]}' \
  --policy 1-mild/conforma/policy.yaml \
  --public-key 1-mild/conforma/cosign-provenance.pub \
  --ignore-rekor \
  --skip-image-sig-check
```

The `--skip-image-sig-check` flag is needed because the provenance key is different from the release signature key — the signature was already verified in step 1.

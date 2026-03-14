# Medium: Conforma

Content inspection of provenance and multi-attestation evaluation using Conforma.

## What This Checks

1. **All mild checks** -- builds on the mild level
2. **Trusted source branch** -- the provenance shows the artifact was built from `refs/heads/main`
3. **SBOM present** -- a CycloneDX SBOM attestation is attached to the artifact

At this level, we go beyond presence checks and inspect provenance *content*. The verify-and-attest task produces a Verification Summary Attestation (VSA) at SLSA_BUILD_LEVEL_2.

Note: Signature verification is handled by the Conforma CLI before policy evaluation. Policies check attestation content.

## Dependencies

This policy requires the Conforma policy library from the `conforma-policy` repository:
- `data.lib` - provides result helpers and attestation filtering
- `data.lib.sbom` - provides SBOM extraction and validation helpers

## VSA Production

The verify-and-attest task evaluates this policy and produces a SLSA VSA. Downstream consumers (e.g. admission controllers) can check the VSA without re-running verification.

## Running

A sample [`policy.yaml`](policy.yaml) composes mild + medium rules together,
showing how levels build on each other:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 2-medium/conforma/policy.yaml
```

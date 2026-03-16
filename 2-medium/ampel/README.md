# Medium: AMPEL

Content inspection and multi-attestation evaluation using [AMPEL](https://github.com/carabiner-dev/ampel).

## What This Checks

1. **Trusted source branch** -- provenance shows the artifact was built from `refs/heads/main`
   - Supports both Tekton and GitHub Actions provenance structures
2. **SBOM present** -- a CycloneDX SBOM attestation is attached

AMPEL can also produce a VSA (SLSA Verification Summary Attestation) as
output using `--attest-results --attest-format=vsa`, decoupling "who
evaluates" from "who enforces."

## Supported Provenance Structures

The policy handles different SLSA provenance formats:
- **Tekton**: `buildDefinition.externalParameters.source.ref`
- **GitHub Actions**: `buildDefinition.externalParameters.workflow.ref`

## Running

```bash
ampel verify <IMAGE_REF> \
  --policy ./policy.hjson \
  --attest-results \
  --attest-format=vsa
```

## Example

Test with the GitHub Actions built image:
```bash
ampel verify ghcr.io/puerco/mild-to-wild-samples:7d7c8864f71708ff051ca35dcb68d9e196034aa8 \
  --policy ./policy.hjson \
  --attest-results \
  --attest-format=vsa
```

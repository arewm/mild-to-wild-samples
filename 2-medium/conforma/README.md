# Medium: Conforma

This policy runs the same SLSA checks as mild. The difference is in how the result is used: the verify-and-attest task evaluates this policy and produces a SLSA VSA at Build Level 2. The VSA captures the verification outcome so downstream consumers can enforce policy without re-running the checks.

The [`policy.yaml`](policy.yaml) supports multiple build systems:
- **Tekton Chains**: Uses `https://tekton.dev/chains/v2/slsa` build type
- **GitHub Actions**: Uses `https://actions.github.io/buildtypes/workflow/v1` build type

## Usage

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 2-medium/conforma/policy.yaml
```

## Supported Images

This policy works with images built by:
- Tekton Pipelines with Chains (original use case)
- GitHub Actions workflows with SLSA provenance (like `ghcr.io/puerco/mild-to-wild-samples:7d7c8864f71708ff051ca35dcb68d9e196034aa8`)

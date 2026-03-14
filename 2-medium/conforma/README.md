# Medium: Conforma

This policy runs the same SLSA checks as mild. The difference is in how the result is used: the verify-and-attest task evaluates this policy and produces a SLSA VSA at Build Level 2. The VSA captures the verification outcome so downstream consumers can enforce policy without re-running the checks.

The [`policy.yaml`](policy.yaml) includes all the mild rules:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 2-medium/conforma/policy.yaml
```

# Mild: Conforma

Two custom rules check that SLSA provenance is present and that the buildType matches an allowlist. The remaining checks — builder identity, source materials, and external parameters — come from the upstream Conforma policy library (`slsa_build_build_service`, `slsa_source_version_controlled`, `external_parameters`). The Conforma CLI verifies cryptographic signatures before policy evaluation.

The [`policy.yaml`](policy.yaml) composes these rules and configures allowed builder IDs and build types:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 1-mild/conforma/policy.yaml
```

See [Conforma CLI documentation](https://github.com/enterprise-contract/ec-cli) for full usage.

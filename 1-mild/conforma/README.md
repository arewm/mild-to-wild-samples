# Mild: Conforma

Presence and basic integrity checks using Conforma (Rego-based policy engine).

## What This Checks

1. **Provenance present** -- a SLSA provenance attestation (v0.2 or v1) is attached to the artifact
2. **Build type accepted** -- the provenance buildType is in the allowed list configured via rule_data
3. **Builder identity** -- via upstream `slsa_build_build_service` rules from conforma-policy
4. **Source materials** -- via upstream `slsa_source_version_controlled` rules from conforma-policy
5. **External parameters** -- via upstream `external_parameters` rules from conforma-policy

Note: The Conforma CLI verifies cryptographic signature validity before policy evaluation. Policies check attestation content and builder identity.

## Dependencies

This policy requires the Conforma policy library from the `conforma-policy` repository:
- `data.lib` - provides result helpers and attestation filtering
- Release policy packages for SLSA build service, source, and external parameter rules

## Scenario

An OCI artifact in a registry with SLSA provenance attached. These checks establish basic trust: provenance is present, signed, and came from an accepted build system.

## Running

A sample [`policy.yaml`](policy.yaml) is provided that composes our custom
rules with upstream SLSA rules. It shows how to configure
allowed builder IDs, build types, and select specific rules:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 1-mild/conforma/policy.yaml
```

See [Conforma CLI documentation](https://github.com/enterprise-contract/ec-cli) for full usage.

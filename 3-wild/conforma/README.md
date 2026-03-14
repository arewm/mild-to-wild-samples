# Wild: Conforma

Trusted task verification in Tekton provenance using Conforma.

## What This Checks

1. **All medium checks** -- builds on the medium level
2. **All tasks trusted** -- tasks in the Tekton provenance are verified against trusted task data (warn rule, not deny)
3. **Tekton provenance available** -- warns if no Tekton provenance is found (needed for task verification)

The policy supports both PipelineRun and TaskRun provenance:
- **PipelineRun provenance** -- checks task bundles against `trusted_task_rules` configuration
- **TaskRun provenance** -- checks resolvedDependencies for task refs against `trusted_task_refs` data

Untrusted tasks produce warnings, not failures. The verify-and-attest task produces a VSA at SLSA_BUILD_LEVEL_3 when all tasks are trusted, or SLSA_BUILD_LEVEL_2 otherwise.

## Why This Matters

Tekton Chains accurately records the tasks that ran. But pipelines are user-customizable -- any task could have injected a different artifact. By verifying that every task is trusted (via pinned bundle digest or git resolver), we close the provenance loop: a pinned task behaves deterministically because it was pinned before the build ran.

Note: Signature verification is handled by the Conforma CLI before policy evaluation. Policies check attestation content.

## Dependencies

This policy requires the Conforma policy library from the `conforma-policy` repository:
- `data.lib` - provides result helpers and attestation filtering
- `data.lib.tekton` - provides Tekton task helpers including trusted task validation
- `data.lib.rule_data` - provides access to rule_data configuration

## Trusted Task Data

Trusted task data lives in `conforma/data/trusted-tasks.yaml` in this repository. For PipelineRun provenance, the policy uses `trusted_task_rules` (pattern-based allow/deny). For TaskRun provenance, it uses `trusted_task_refs` (explicit URI and digest mappings).

## Running

A sample [`policy.yaml`](policy.yaml) composes all three levels and includes
the trusted task bundle data source:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 3-wild/conforma/policy.yaml
```

The `trusted_task_rules` will be loaded from your configured policy data source.

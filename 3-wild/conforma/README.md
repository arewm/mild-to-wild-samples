# Wild: Conforma

This policy adds trusted task verification on top of the mild checks. It inspects the Tekton provenance to confirm that every task matches a known reference — either an OCI bundle digest (for PipelineRun provenance via `trusted_task_rules`) or a git commit (for TaskRun provenance via `trusted_task_refs` in `conforma/data/trusted-tasks.yaml`).

When we can identify the tasks that ran, we know the build environment provided the isolation guarantees required for SLSA Build Level 3. If any task reference is untrusted or unrecognized, the rule produces a warning. The presence of that warning tells the verify-and-attest task that L3 cannot be claimed, so it assigns L2 in the VSA instead.

The [`policy.yaml`](policy.yaml) composes all three levels:

```bash
ec validate image \
  --image <IMAGE_REF> \
  --policy 3-wild/conforma/policy.yaml
```

# Wild: Conforma

This policy adds trusted task verification on top of the mild checks. It inspects the Tekton provenance to confirm that every task matches a known reference — either an OCI bundle digest (for PipelineRun provenance via `trusted_task_rules`) or a git commit (for TaskRun provenance via `trusted_task_refs` in `conforma/data/trusted-tasks.yaml`).

When we can identify the tasks that ran, we know the build environment provided the isolation guarantees required for SLSA Build Level 3. If any task reference is untrusted or unrecognized, the rule produces a warning. The presence of that warning tells the verify-and-attest task that L3 cannot be claimed, so it assigns L2 in the VSA instead.

Like medium, verification requires two passes because the base image and built image have different signing keys and builder configurations. The wild policy adds trusted task rules on top.

## Usage

Run the demo script from the repo root:

```bash
./3-wild/conforma/verify.sh
```

The script performs the following steps via `generate-vsa.sh`:

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

Pass 2 — Verify the built image with the wild policy (key-based, Tekton Chains):

```bash
ec validate image \
  --images '{"components":[{"name":"built-image","containerImage":"<BUILT_IMAGE_REF>"}]}' \
  --policy 3-wild/conforma/policy.yaml \
  --public-key provenance.pub \
  --ignore-rekor
```

## VSA Generation

The `scripts/generate-vsa.sh` script runs both passes and generates a SLSA VSA:

```bash
scripts/generate-vsa.sh \
  --image <BUILT_IMAGE_REF> \
  --policy 3-wild/conforma/policy.yaml \
  --public-key provenance.pub \
  --ignore-rekor \
  --base-image-policy 1-mild/conforma/policy.yaml \
  --base-image-key 1-mild/conforma/cosign-provenance.pub \
  --base-image-release-key 1-mild/conforma/cosign-release.pub \
  --vsa-signing-key vsa.key
```

Use `--no-attach` to produce the VSA predicate without pushing it to the registry.

## Why custom rules instead of the upstream `trusted_task` package?

Conforma's standard library includes a full `trusted_task` package (`trusted_task.trusted`, `trusted_task.pinned`, etc.) that handles both PipelineRun bundle refs and TaskRun git resolver refs. It supports pattern-based allow/deny lists with version constraints, effective dates, and proper git URL normalization. In production, this is what you'd use.

The custom `wild.rego` rules in this demo exist for two reasons:

1. **Warn instead of deny.** The upstream `trusted_task.trusted` is a `deny` rule — policy evaluation fails if an untrusted task is found. Our custom rules use `warn` instead, so the policy always passes. The presence or absence of warnings is what determines whether the VSA claims L2 or L3. This lets a single policy evaluation produce a graded result rather than a binary pass/fail.

2. **Simplicity for the demo.** The upstream package includes additional checks (pinned refs, tagged refs, version currency, trusted parameters, trusted artifacts) that are valuable in production but add complexity for a conference demo. The custom rules isolate the core concept: match task refs against an allowlist, warn if untrusted.

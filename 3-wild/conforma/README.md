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

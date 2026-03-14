# Wild

**Can we understand the provenance well enough to upgrade the trust level?**

The wild level adds trusted task verification on top of the medium checks. When the provenance records which task definitions were used and those tasks match a known allowlist, we know the build environment provided the isolation guarantees required for SLSA Build Level 3. This lets us upgrade the VSA from Level 2 to Level 3.

The [tekton/](tekton/) directory contains the build and verification tasks. The verify-and-attest task evaluates the policy and assigns L2 or L3 based on whether the trusted task check passes or produces a warning. Trusted task data is configured in `conforma/data/trusted-tasks.yaml`.

See [conforma/](conforma/) and [ampel/](ampel/) for engine-specific policies and invocation instructions.

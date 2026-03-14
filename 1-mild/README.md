# Mild

**Is this attestation here? Is it valid?**

At the mild level, we perform presence and basic integrity checks:

- Does the artifact have a SLSA provenance attestation?
- Is the build type accepted?
- Is the builder identity trusted?
- Are source materials version controlled?
- Are external parameters properly captured?

This is where everyone should start. The attestation format is the interface --
the build system (GitHub Actions, Tekton, etc.) doesn't matter for these checks.

See [conforma/](conforma/) and [ampel/](ampel/) for engine-specific policies
and invocation instructions.

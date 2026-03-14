# Medium

**What does it say inside? Can I combine multiple attestations?**

At the medium level, we go beyond presence checks and inspect provenance
*content*:

- Which source branch was used (trusted branch check)?
- Is there an SBOM attached to the artifact?

The verify-and-attest task produces a Verification Summary Attestation (VSA) at
SLSA_BUILD_LEVEL_2, decoupling "who evaluates" from "who enforces." An admission
controller can check the VSA without re-running verification.

See [conforma/](conforma/) and [ampel/](ampel/) for engine-specific policies
and invocation instructions.

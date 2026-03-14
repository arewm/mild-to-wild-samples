# Medium

**Can we verify our own build and summarize the result?**

The medium level runs the same SLSA provenance checks as mild against a newly built image, then produces a Verification Summary Attestation (VSA) at SLSA Build Level 2. This decouples verification from enforcement — downstream consumers like admission controllers check the VSA instead of re-evaluating the provenance themselves.

See [conforma/](conforma/) and [ampel/](ampel/) for engine-specific policies and invocation instructions.

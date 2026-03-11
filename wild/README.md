# Wild

**Did those steps actually produce this artifact?**

At the wild level, we address the deeper trust question: the provenance
records what tasks ran, but did those tasks actually *produce* this artifact?

Tekton Chains accurately records tasks, but pipelines are user-customizable.
Any task could have injected a different artifact. By verifying that every task
used a **pinned, trusted bundle digest**, we close the provenance loop -- a
pinned task behaves deterministically because it was pinned before the build ran.

## Generalizing the Pattern

While this demo uses Tekton task bundles, the pattern applies to any build platform:

- **Tekton**: Verify task bundles are from approved catalog, pinned by digest
- **GitHub Actions**: Verify workflows/actions are from trusted repos, pinned to commit SHAs
- **GitLab CI**: Verify CI templates are from trusted projects
- **Jenkins**: Verify pipeline libraries are from approved sources

The concept is universal: **verify the build components themselves are audited and immutable**,
not just that the provenance is signed.

See [conforma/](conforma/) and [ampel/](ampel/) for engine-specific policies
and invocation instructions.

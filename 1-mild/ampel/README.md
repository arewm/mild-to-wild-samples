# Mild: AMPEL

Presence, signer identity, and SLSA level checks using
[AMPEL](https://github.com/carabiner-dev/ampel).

To run this policy download the latest binary of AMPEL from the github release
and run according to the instructions below.

## What This Checks

1. **Provenance present** -- a SLSA provenance attestation is attached
2. **Signer identity** -- verifies the UBI image builda attestation using its public signing key (id: a9d7f4c3752c4aee)
3. **SLSA Verification** -- Performs the SLSA spec verification of the image build provenance.

## Running

```bash
ampel verify "$(crane manifest ghcr.io/puerco/mild-to-wild-samples | jq -r '.annotations["org.opencontainers.image.base.digest"]')" \
   --policy 1-mild/ampel/policy.hjson \
   --collector coci:registry.access.redhat.com/ubi10/ubi-minimal:latest \
   --context 'buildPoint:git+https://gitlab.com/redhat/rhel/containers/ubi10-minimal.git' \
   --attest-format vsa \
   --attest-results=true \
   --results-path=output/mild/ampel/base.vsa.json
```

See the [AMPEL project](https://github.com/carabiner-dev/ampel) for full usage.

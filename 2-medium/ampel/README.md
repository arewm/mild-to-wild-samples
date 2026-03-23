# Medium: AMPEL

Content inspection and multi-attestation evaluation using [AMPEL](https://github.com/carabiner-dev/ampel).

## What This Checks

1. **SLSA Verification** -- Performs the SLSA spec verification of our image's build provenance
2. **VSA Verification&& -- Checks the image's Verification Summary to ensure our base is verified

AMPEL can also produce a VSA (SLSA Verification Summary Attestation) as output
using `--attest-results --attest-format=vsa`, decoupling "who evaluates" from
"who enforces."

## Running

```bash
"$AMPEL" verify "$(crane digest ghcr.io/puerco/mild-to-wild-samples)" \
    --collector oci:ghcr.io/puerco/mild-to-wild-samples \
    --policy 2-medium/ampel/policy.hjson \
    --attestation output/mild/ampel/base.vsa.json \
    --attest-format vsa \
    --attest-results=true \
    --results-path=output/medium/image.vsa.json
```

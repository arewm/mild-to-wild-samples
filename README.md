# From Mild to Wild: How Hot Can Your SLSA Be?

Sample policies for the [From Mild to Wild](https://slides.arewm.com/presentations/2026-03-23-from-mild-to-wild/)
talk at Open Source SecurityCon 2026, demonstrating three levels of SLSA policy
enforcement with two interchangeable policy engines.

## Structure

| Level | What it checks | Directory |
|-------|---------------|-----------|
| **Mild** | Attestation presence, signer identity, SLSA level | [`1-mild/`](1-mild/) |
| **Medium** | Provenance content inspection, multi-attestation evaluation, VSA/SVR production | [`2-medium/`](2-medium/) |
| **Wild** | Trusted task bundle digests in Tekton provenance | [`3-wild/`](3-wild/) |

Each level contains policies for both engines:

- **[Conforma](https://conforma.dev)** -- Rego-based policy engine built around Tekton/Konflux
- **[AMPEL](https://github.com/carabiner-dev/ampel)** -- Policy engine for in-toto attestation evaluation, produces VSAs and SVRs

## Testing (Conforma policies)

The Conforma policies have OPA tests that run with `ec opa test`. The test
runner needs the Conforma CLI and the upstream policy library (which provides
`data.lib` helpers, attestation filtering, Tekton task helpers, etc.).

**Prerequisites:**

1. The [Conforma CLI](https://github.com/enterprise-contract/ec-cli) (`ec`
   binary). Standard `opa` will not work -- the tests depend on `ec`-specific
   OPA extensions.
2. The [Conforma policy library](https://github.com/conforma/policy) cloned
   locally. Tests load `policy/lib/` and `policy/release/lib/` from this repo.

**Running tests:**

The `test_policy.sh` script locates both dependencies via environment variables.
By default it looks for sibling directories named `conforma-cli` and
`conforma-policy`:

```bash
# If repos are sibling directories (the default), just run:
./test_policy.sh

# Otherwise, set paths explicitly:
export CONFORMA_POLICY_PATH=/path/to/conforma-policy
export CONFORMA_CLI_PATH=/path/to/conforma-cli
./test_policy.sh

# Run a specific level:
./test_policy.sh mild
./test_policy.sh medium
./test_policy.sh wild
```

## Building images (Wild level)

The `3-wild/tekton/` directory includes a Tekton Task for building images with
SLSA v1.0 provenance via Tekton Chains.

**Prerequisites:**

- KinD (or any Kubernetes cluster)
- kubectl
- cosign

**Cluster setup:**

```bash
# Create KinD cluster (set KIND_EXPERIMENTAL_PROVIDER to match your runtime)
export KIND_EXPERIMENTAL_PROVIDER=podman  # or docker
kind create cluster

# Install Tekton Pipelines (latest stable)
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl wait -n tekton-pipelines --for=condition=ready pod -l app.kubernetes.io/part-of=tekton-pipelines --timeout=300s

# Install Tekton Chains (latest stable)
kubectl apply -f https://storage.googleapis.com/tekton-releases/chains/latest/release.yaml
kubectl wait -n tekton-chains --for=condition=ready pod -l app.kubernetes.io/part-of=tekton-chains --timeout=300s
```

**Configure Chains for SLSA v1.0:**

```bash
# Generate cosign key pair (no password)
COSIGN_PASSWORD="" cosign generate-key-pair

# Create signing secret
kubectl create secret generic signing-secrets \
  --from-file=cosign.key=cosign.key \
  --from-file=cosign.pub=cosign.pub \
  --from-file=cosign.password=<(echo -n "") \
  -n tekton-chains

# Configure Chains — use slsa/v2alpha4 for SLSA v1.0 provenance
# (slsa/v1 is a backward-compat alias for in-toto, NOT SLSA v1.0)
kubectl patch configmap chains-config -n tekton-chains --type merge -p '{
  "data": {
    "artifacts.taskrun.format": "slsa/v2alpha4",
    "artifacts.taskrun.storage": "oci",
    "artifacts.pipelinerun.format": "slsa/v2alpha4",
    "artifacts.pipelinerun.storage": "oci",
    "artifacts.oci.storage": "oci",
    "transparency.enabled": "false"
  }
}'

# Restart Chains controller
kubectl rollout restart deployment tekton-chains-controller -n tekton-chains
```

**Registry credentials:**

```bash
# Create docker-registry secret
kubectl create secret docker-registry registry-credentials \
  --docker-server=<your-registry> \
  --docker-username=<username> \
  --docker-password=<password>

# Annotate for Tekton
kubectl annotate secret registry-credentials tekton.dev/docker-0=<your-registry>

# Link to default service account
kubectl patch serviceaccount default -p '{"secrets":[{"name":"registry-credentials"}]}'
```

**Run the build:**

```bash
# Apply the Task
kubectl apply -f 3-wild/tekton/tasks/build-and-push/0.1/build-and-push.yaml

# Create a TaskRun
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: mild-to-wild-build
spec:
  taskRef:
    name: build-and-push
  params:
    - name: IMAGE
      value: <your-registry>/mild-to-wild-samples:latest
    - name: SOURCE_URL
      value: https://github.com/arewm/mild-to-wild-samples
    - name: SOURCE_REF
      value: main
EOF
```

**Verify attestation:**

```bash
# Check results
kubectl get taskrun mild-to-wild-build -o jsonpath='{.status.results}' | jq .

# Check Chains signed annotation
kubectl get taskrun mild-to-wild-build -o jsonpath='{.metadata.annotations.chains\.tekton\.dev/signed}'

# Verify attestation with cosign
cosign verify-attestation --key cosign.pub --insecure-ignore-tlog \
  --type https://slsa.dev/provenance/v1 \
  <your-registry>/mild-to-wild-samples:latest
```

## Key Takeaway

Policy engines are interchangeable because attestation standards are open
(in-toto, SLSA). Your policies travel with you -- pick the engine that fits
your stack.

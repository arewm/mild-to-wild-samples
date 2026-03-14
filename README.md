# From Mild to Wild: How Hot Can Your SLSA Be?

Sample policies for the [From Mild to Wild](https://slides.arewm.com/presentations/2026-03-23-from-mild-to-wild/)
talk at Open Source SecurityCon 2026, demonstrating three levels of SLSA policy
enforcement with two interchangeable policy engines.

## Structure

| Level | What it checks | Directory |
|-------|---------------|-----------|
| **Mild** | Provenance presence, build type, builder identity, source materials, external parameters | [`1-mild/`](1-mild/) |
| **Medium** | Source branch, SBOM presence, VSA production | [`2-medium/`](2-medium/) |
| **Wild** | Trusted task verification (PipelineRun and TaskRun provenance) | [`3-wild/`](3-wild/) |

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

The `3-wild/tekton/` directory includes tasks for building and verifying images with
SLSA v1.0 provenance. Builds use the git resolver to reference tasks, enabling trusted
task verification.

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

**Generate key pairs:**

Two separate cosign key pairs are needed:
- **Provenance signing** (for Tekton Chains)
- **VSA signing** (for verify-and-attest task)

```bash
# Generate provenance signing key
COSIGN_PASSWORD="" cosign generate-key-pair
mv cosign.key provenance.key
mv cosign.pub provenance.pub

# Generate VSA signing key
COSIGN_PASSWORD="" cosign generate-key-pair
mv cosign.key vsa.key
mv cosign.pub vsa.pub
```

**Configure Chains:**

```bash
# Create Chains signing secret
kubectl create secret generic signing-secrets \
  --from-file=cosign.key=provenance.key \
  --from-file=cosign.pub=provenance.pub \
  --from-file=cosign.password=<(echo -n "") \
  -n tekton-chains

# Configure Chains for SLSA v1.0 (slsa/v2alpha4 format, NOT slsa/v1)
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

**Create verification keys secret:**

```bash
# Create secret with both provenance public key and VSA private key
kubectl create secret generic mild-to-wild-keys \
  --from-file=provenance-pub=provenance.pub \
  --from-file=vsa-key=vsa.key
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

**Build with git resolver:**

The IMAGE param is a repository (no tag) — the task generates a timestamp tag automatically.

```bash
# Get current commit SHA (MUST be full 40-character SHA for git resolver)
COMMIT=$(git rev-parse HEAD)

# Build
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: mild-to-wild-build
spec:
  taskRef:
    resolver: git
    params:
      - name: url
        value: https://github.com/arewm/mild-to-wild-samples
      - name: revision
        value: ${COMMIT}
      - name: pathInRepo
        value: 3-wild/tekton/tasks/build-and-push/0.1/build-and-push.yaml
  params:
    - name: IMAGE
      value: <your-registry>/mild-to-wild-samples
    - name: SOURCE_URL
      value: https://github.com/arewm/mild-to-wild-samples
    - name: SOURCE_REF
      value: main
EOF

# Wait for build to complete
kubectl wait --for=condition=Succeeded taskrun/mild-to-wild-build --timeout=10m

# Get the generated image tag
BUILD_TAG=$(kubectl get taskrun mild-to-wild-build -o jsonpath='{.status.results[?(@.name=="IMAGE_URL")].value}' | sed 's/.*://')
echo "Built image tag: ${BUILD_TAG}"
```

**Verify with medium policy (SLSA Build Level 2):**

```bash
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: mild-to-wild-verify-medium
spec:
  taskRef:
    resolver: git
    params:
      - name: url
        value: https://github.com/arewm/mild-to-wild-samples
      - name: revision
        value: ${COMMIT}
      - name: pathInRepo
        value: 3-wild/tekton/tasks/verify-and-attest/0.1/verify-and-attest.yaml
  workspaces:
    - name: keys
      secret:
        secretName: mild-to-wild-keys
  params:
    - name: IMAGE
      value: <your-registry>/mild-to-wild-samples:${BUILD_TAG}
    - name: POLICY
      value: github.com/arewm/mild-to-wild-samples//2-medium/conforma?ref=main
EOF
```

**Verify with wild policy (SLSA Build Level 3):**

```bash
kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: mild-to-wild-verify-wild
spec:
  taskRef:
    resolver: git
    params:
      - name: url
        value: https://github.com/arewm/mild-to-wild-samples
      - name: revision
        value: ${COMMIT}
      - name: pathInRepo
        value: 3-wild/tekton/tasks/verify-and-attest/0.1/verify-and-attest.yaml
  workspaces:
    - name: keys
      secret:
        secretName: mild-to-wild-keys
  params:
    - name: IMAGE
      value: <your-registry>/mild-to-wild-samples:${BUILD_TAG}
    - name: POLICY
      value: github.com/arewm/mild-to-wild-samples//3-wild/conforma?ref=main
EOF
```

**Check VSAs:**

```bash
# Get image digest
IMAGE_DIGEST=$(kubectl get taskrun mild-to-wild-verify-medium -o jsonpath='{.status.results[?(@.name=="IMAGE_DIGEST")].value}')

# List referrers
oras discover <your-registry>/mild-to-wild-samples@${IMAGE_DIGEST}

# Verify VSAs
cosign verify-attestation --key vsa.pub --insecure-ignore-tlog \
  --type https://slsa.dev/verification_summary/v1 \
  <your-registry>/mild-to-wild-samples:${BUILD_TAG}
```

## Key Takeaway

Policy engines are interchangeable because attestation standards are open
(in-toto, SLSA). Your policies travel with you -- pick the engine that fits
your stack.

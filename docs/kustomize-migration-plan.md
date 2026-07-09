## Plan: Migrate Kubernetes deployment to Kustomize with parameterization

Migrate from plain manifest deployment to Kustomize-based deployment, making the number of replicas and namespace configurable parameters in the GitHub workflow.

**TL;DR**: Create a Kustomize structure with base manifests and environment-specific overlays. Update the GitHub workflow to build Kustomize configurations and deploy using parameterized values for replicas and namespace.

**Steps**

1. Create Kustomize directory structure (*independent*)
   - Create `k8s/base/` directory
   - Create `k8s/overlays/` directory for environment-specific configurations

2. Set up base Kustomize configuration (*depends on step 1*)
   - Move existing manifests to `k8s/base/`
   - Create `k8s/base/kustomization.yaml` referencing deployment, service, and ingress

3. Create overlay for configurable parameters (*depends on step 2*)
   - Create `k8s/overlays/default/kustomization.yaml`
   - Add replica count patch using Kustomize's built-in replica transformer
   - Configure namespace via Kustomize namespace field

4. Update GitHub workflow to use Kustomize (*depends on step 3*)
   - Replace `azure/k8s-deploy` action with Kustomize build + kubectl apply
   - Add workflow inputs for `replicas` (default: 2) and `namespace` (default: amohammadi)
   - Use `kustomize edit set replicas` or patch to dynamically set replica count
   - Use `kustomize edit set namespace` to set target namespace
   - Build manifests with `kustomize build` and apply with `kubectl apply`

5. Clean up old manifest directory (*depends on step 4*)
   - Remove or archive the old `manifests/` directory

**Verification**

1. Validate Kustomize configuration locally: `kustomize build k8s/overlays/default`
2. Test workflow with different parameters (manual workflow dispatch)
3. Verify deployment in Kubernetes cluster with correct replicas and namespace
4. Confirm image is updated correctly in deployment

**Relevant files**

- [.github/workflows/build-and-deploy.yaml](.github/workflows/build-and-deploy.yaml#L76-L92) — Deploy job to update with Kustomize commands
- [manifests/deployment.yaml](manifests/deployment.yaml#L5) — Move to k8s/base/ and remove hardcoded replicas
- [manifests/service.yaml](manifests/service.yaml) — Move to k8s/base/
- [manifests/ingress.yaml](manifests/ingress.yaml) — Move to k8s/base/

**Decisions**

- Use overlays structure for flexibility (supports multiple environments in future)
- Set replicas and namespace as workflow parameters with sensible defaults
- Keep workflow trigger on all branch pushes as currently configured
- Use `kubectl` for deployment after Kustomize build (compatible with current k8s-set-context action)

**Further Considerations**

1. **Environment-specific configurations**: Do you want separate overlays for dev/staging/prod, or is a single parameterized overlay sufficient?
   - Option A: Single overlay with workflow parameters (simpler, current requirement)
   - Option B: Multiple overlays (dev/prod) with different defaults (more GitOps-friendly)
   
2. **Additional parameters**: Besides replicas and namespace, would you like to parameterize other values?
   - Ingress host
   - Resource limits/requests
   - Environment variables

3. **Workflow trigger**: Keep current behavior (deploy on every push to any branch), or deploy only on specific branches?
   - Option A: Keep current (deploy on all branches)
   - Option B: Deploy only on main/specific branches

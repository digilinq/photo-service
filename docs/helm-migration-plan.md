## Plan: Migrate to Helm-based deployment with environment-specific values

Migrate from plain Kubernetes manifests to Helm chart deployment with separate values files for Test and Production environments.

**TL;DR**: Create a Helm chart with templated manifests and environment-specific values files. Update the GitHub workflow to deploy to Test environment (namespace: solobit-test) on feature branches and Production environment (namespace: solobit) on main branch, using Helm with the appropriate values file.

**Steps**

1. **Create Helm chart structure** (*independent*)
   - Create `helm/photo-service/` directory
   - Create `Chart.yaml` with app metadata (name, version, appVersion)
   - Create `values.yaml` with default/common values
   - Create `.helmignore` file

2. **Create templated manifests** (*depends on step 1*)
   - Create `templates/deployment.yaml` from current manifest with Helm templating
   - Create `templates/service.yaml` with Helm templating
   - Create `templates/ingress.yaml` with Helm templating
   - Create `templates/_helpers.tpl` for reusable template functions
   - Create `templates/NOTES.txt` for post-install information

3. **Create environment-specific values files** (*depends on step 1*)
   - Create `helm/values-test.yaml` for Test environment:
     - Namespace: solobit-test
     - Ingress host: photo-tst.solobit.nl
     - Replicas: (user to specify, suggest 1)
     - Resources: (user to specify, suggest lower limits)
   - Create `helm/values-prod.yaml` for Production environment:
     - Namespace: solobit
     - Ingress host: photo.solobit.nl
     - Replicas: (user to specify, suggest 2-3)
     - Resources: (user to specify, suggest production-grade limits)

4. **Update GitHub workflow for Helm deployment** (*depends on steps 2, 3*)
   - Add environment detection logic (main branch = prod, others = test)
   - Replace `azure/k8s-deploy` with Helm install/upgrade commands
   - Set namespace and values file based on detected environment
   - Use Helm's `--set image.tag` to inject the built Docker image tag
   - Add `--create-namespace` flag for namespace creation
   - Keep existing k8s-set-context step for authentication

5. **Remove old manifests directory** (*depends on step 4*)
   - Delete `manifests/` directory once Helm deployment is working

6. **Add Acceptance environment support** (*optional, future phase*)
   - Create `helm/values-acceptance.yaml`
   - Add branch/trigger mapping for acceptance environment

**Verification**

1. Validate Helm chart locally: `helm lint helm/photo-service`
2. Dry-run template rendering for each environment:
   - `helm template photo-service helm/photo-service -f helm/values-test.yaml`
   - `helm template photo-service helm/photo-service -f helm/values-prod.yaml`
3. Test workflow on feature branch → verify Test deployment
4. Test workflow on main branch → verify Production deployment
5. Verify namespace isolation and correct ingress hosts
6. Verify image tag updates correctly in deployments

**Relevant files**

- `manifests/deployment.yaml` — Convert to `helm/photo-service/templates/deployment.yaml`
- `manifests/service.yaml` — Convert to `helm/photo-service/templates/service.yaml`
- `manifests/ingress.yaml` — Convert to `helm/photo-service/templates/ingress.yaml`
- `.github/workflows/build-and-deploy.yaml` — Update deploy job with Helm commands and environment logic

**Decisions**

- Use GitHub Flow: main → Production, feature branches → Test
- Skip Acceptance environment initially (can add later)
- Same Kubernetes cluster with different namespaces (solobit-test, solobit)
- Environment-specific configurations:
  - Replicas (Test: fewer, Prod: more)
  - Resource limits (Test: lower, Prod: higher)
  - Ingress hosts (Test: photo-tst.solobit.nl, Prod: photo.solobit.nl)
- No Helm chart repository publishing (deploy directly from repo)
- Use Helm 3 (no Tiller required)
- Values files stored in `helm/` directory at repo root for easy access

**Further Considerations**

1. **Test environment replicas**: How many replicas for Test? (Recommend 1)
2. **Production replicas**: How many for Production? (Recommend 2-3)
3. **Resource limits**: What CPU/memory limits for each environment?
   - Test suggestion: requests(cpu: 100m, memory: 256Mi), limits(cpu: 500m, memory: 512Mi)
   - Prod suggestion: requests(cpu: 200m, memory: 512Mi), limits(cpu: 1000m, memory: 1Gi)
4. **Health checks**: Should we add liveness/readiness probes? (Recommend yes for production)
5. **Acceptance environment**: When to add Acceptance? Which branch pattern or trigger?

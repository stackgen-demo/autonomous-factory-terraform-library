# AWS/EKS and Harness onboarding contract

This knowledge is a reference for an Aiden agent onboarding one application. It is not a rendered output.

Required platform facts:

- GitHub repository and default branch.
- AWS account, region, existing EKS cluster, target namespace, and an existing S3 state bucket.
- Optional `spec.aws.permissionsBoundaryArn`: an operator-approved policy that
  already exists in the application account. Follow the pinned contract's
  `terraformRoot.permissionsBoundary` rules; agents never manage this policy.
- Terraform root and unique state key. Use one key per application and environment.
- Harness account and delegate selector. Organization defaults to `default`; project defaults to `default` only when the application does not specify one.
- Existing Harness GitHub, AWS/ECR, and Kubernetes connector references. The AWS connector must be able to read the declared ECR repository, and the Kubernetes connector must target the declared EKS cluster.
- For the native CI reference, `spec.harness.imageRegistryConnectorRef` selects
  a verified image-registry connector for the test image; preserve inherited scope
  prefixes such as `account.`. Discover/reuse it rather than inventing credentials.
- Harness service, Dev environment, and infrastructure identifiers. The delivery workflow may create them when absent, then verify them by readback.
- Application build context, Dockerfile, test image/command, ECR repository, deployment manifest path, and Backstage catalog path.
- Harness CI build namespace and service account with ECR push identity and an eligible Kubernetes connector. Native codebase checkout uses the existing Harness GitHub connector; the CI reference does not use a separate Kubernetes checkout-token Secret.

The application repository declares these non-secret values in `.autonomous-factory/application.yaml`, validated against `contracts/application-factory-v1.schema.json`. Credentials stay in Aiden integrations, Harness secrets/connectors, and the remote runner.

Select Linear or Jira in `spec.issueTracker`, including the project/team key,
optional site URL, issue-key pattern, and discovered status mapping. Legacy
`spec.linear` remains valid; do not set both. The onboarding agent creates or
reuses the selected Aiden integration and verifies an actual project/issue read.
Delivery agents discover ticket operations through that integration; runner
scripts do not implement tracker API calls. Source PRs carry exactly one
`Ticket: TEAM-123` reference, or the selected provider's `Linear:`/`Jira:` form.

Harness `baseUrl` controls the instance and UI links; optional `apiBaseUrl`
controls the gateway route. Defaults are `https://app.harness.io` and its
`/gateway` route. Verify that the integration, Vault record, and runner target
the same instance before delivery. Connector presence alone is not verified
connectivity.

Use the repository's onboarding adapter to convert this contract into non-secret Terraform inputs. Do not maintain a second handwritten copy of application values.

Use the pipeline path in the pinned central contract. Agent mode's v4 reference
is copied with application-specific placeholder substitutions, not reimplemented
as custom build-job orchestration. It uses native Terraform Plan/Apply, a CI stage
with managed codebase checkout, a Run test step and BuildAndPushECR, then native
K8sRollingDeploy. Build, Terraform, manifest source and image tag use the same
verified deployment SHA (the generated PR merge SHA when artifacts changed).
Keep each stage fail-closed. Preserve compatible existing external pipelines;
changing them to the reference requires a reviewed migration.

Build and test run from a clean checkout. Treat `runtime.testCommand` as the test invocation, not proof that dependencies are already present. Inspect the build context and prepend its deterministic locked dependency installation when required—for example, `npm ci` when `package-lock.json` exists—before running the declared test command.

Capability mappings remain registry-driven. If a detected AWS dependency is absent from `contracts/autonomous-factory-v4.json`, block with the missing capability ID; do not improvise an ungoverned module.

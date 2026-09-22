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
- Harness service, Dev environment, and infrastructure identifiers. The delivery workflow may create them when absent, then verify them by readback.
- Application build context, Dockerfile, test image/command, ECR repository, deployment manifest path, and Backstage catalog path.
- Build-job namespace and service account, plus the name of a Kubernetes Secret whose `token` key can clone the application repository. These are references only; never store the token in the contract.

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

Use `templates/harness/aws-eks-dev-pipeline-v2.yaml.tftpl` as structural guidance. Adapt its build job and placeholders from the application contract; change the test image and command to match the repository. Preserve native `TerraformPlan`, `TerraformApply`, and `K8sRollingDeploy` steps, each stage's failure strategy, and the immutable `commit_sha` input. The build uses that immutable application SHA; Terraform reads the merged delivery files from the repository's default branch because the original application SHA predates the generated IaC PR. A successful rolling deployment is the delivery success criterion.

Build and test run from a clean checkout. Treat `runtime.testCommand` as the test invocation, not proof that dependencies are already present. Inspect the build context and prepend its deterministic locked dependency installation when required—for example, `npm ci` when `package-lock.json` exists—before running the declared test command.

Capability mappings remain registry-driven. If a detected AWS dependency is absent from `contracts/autonomous-factory-v4.json`, block with the missing capability ID; do not improvise an ungoverned module.

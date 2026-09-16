# AWS/EKS and Harness onboarding contract

This knowledge is a reference for an Aiden agent onboarding one application. It is not a rendered output.

Required platform facts:

- GitHub repository and default branch.
- AWS account, region, existing EKS cluster, target namespace, and an existing S3 state bucket.
- Terraform root and unique state key. Use one key per application and environment.
- Harness account and delegate selector. Organization defaults to `default`; project defaults to `default` only when the application does not specify one.
- Existing Harness GitHub and Kubernetes connector references. The Kubernetes connector must target the declared EKS cluster.
- Harness service, Dev environment, and infrastructure identifiers. Create them during onboarding if absent, then verify them by readback.
- Application build context, Dockerfile, test image/command, ECR repository, deployment manifest path, and Backstage catalog path.
- Build-job namespace and service account, plus the name of a Kubernetes Secret whose `token` key can clone the application repository. These are references only; never store the token in the contract.

The application repository declares these non-secret values in `.autonomous-factory/application.yaml`, validated against `contracts/application-factory-v1.schema.json`. Credentials stay in Aiden integrations, Harness secrets/connectors, and the remote runner.

Use `templates/harness/aws-eks-dev-pipeline-v2.yaml.tftpl` as structural guidance. Adapt its build job and placeholders from the application contract; change the test image and command to match the repository. Preserve native `TerraformPlan`, `TerraformApply`, and `K8sRollingDeploy` steps and the immutable `commit_sha` input. A successful rolling deployment is the delivery success criterion.

Capability mappings remain registry-driven. If a detected AWS dependency is absent from `contracts/autonomous-factory-v4.json`, block with the missing capability ID; do not improvise an ungoverned module.

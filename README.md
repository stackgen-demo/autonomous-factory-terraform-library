# Autonomous Factory reference library

This repository is the governed catalog used by the Autonomous Factory Aiden workflow. It contains registered AWS capabilities and reference material for generating Terraform, Backstage system models, and Harness Dev pipelines.

## Attach an application

1. Add `.autonomous-factory/application.yaml` to the application repository and validate it against `contracts/application-factory-v1.schema.json`.
2. Declare only capabilities registered by `contracts/autonomous-factory-v4.json`.
3. Keep credentials out of the repository. Configure them in Aiden integrations, Harness connectors/secrets, and the in-cluster remote runner.
4. Ensure the declared EKS cluster and S3 Terraform state bucket exist. Harness organization and project default to `default` when omitted.
5. Install the workflow once for that application with a unique resource prefix and sync its generated runner runtime configuration.

See `knowledge/aws-eks-harness-onboarding.md` for the onboarding and verification contract. The templates are references for agent-authored output; they are not deterministic renderers.

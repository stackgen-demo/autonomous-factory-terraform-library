# Autonomous Factory reference library

This repository is the governed catalog used by the Autonomous Factory Aiden workflow. It contains registered AWS capabilities and reference material for generating Terraform, Backstage system models, and Harness Dev pipelines.

## Attach an application

1. Add `.autonomous-factory/application.yaml` to the application repository and validate it against `contracts/application-factory-v1.schema.json`.
2. Declare only capabilities registered by `contracts/autonomous-factory-v4.json`; an empty list is valid for an app needing only the EKS foundation.
3. Keep credentials out of the repository. Configure them in Aiden integrations, Harness connectors/secrets, and the in-cluster remote runner.
4. Ensure the declared EKS cluster and S3 Terraform state bucket exist. Harness organization and project default to `default` when omitted.
5. Install the workflow once for that application with a unique resource prefix and sync its generated runner runtime configuration.

See `knowledge/aws-eks-harness-onboarding.md` for the onboarding and verification contract. The templates are references for agent-authored output; they are not deterministic renderers.

The contract supports application-only changes and foundation-only bootstrap.
No dependency signal is not a failure when evidence confirms `NO_CHANGE`.
The native pipeline reference provisions the foundation before publishing the
container, pins Terraform to the selected delivery commit, and enforces a
refreshed zero-change plan for code-only delivery before native Apply.
Existing deployments need a reviewed pipeline upgrade before using this path.

## Validation

Run `ruby tests/test_permissions_boundary.rb` for the boundary plan policy and
`sh tests/test-root.sh` for offline OpenTofu plans of the root reference with
mocked AWS/Kubernetes providers. These tests do not apply infrastructure or
require cloud credentials. Canonical customer initialization remains in the
[factory onboarding guide](https://github.com/stackgen-demo/autonomous-factory-demo/blob/main/docs/autonomous-factory-portability.md).

Run `ruby tests/test_delivery.rb` for foundation contracts, native-stage ordering,
immutable Terraform checkout, and executable mode-specific plan-guard checks.

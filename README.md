# Autonomous Factory reference library

This repository is the governed catalog used by the Autonomous Factory Aiden workflow. It contains registered AWS capabilities and reference material for generating Terraform, Backstage system models, and Harness Dev pipelines.

## Agent-owned delivery contract

`contracts/autonomous-factory-v5.json` is the agent-owned execution contract. It
preserves the v4 capability catalog and Terraform safety policy, but replaces
pipeline-template identity requirements with behavioral compatibility: native
step types, immutable revision propagation, enforced plan review, safe dependency
ordering and correlated execution evidence. Existing pipeline stage/input names
need not match the reference. Equivalent governance must be verified, not merely
claimed by an agent; prompts and agent-editable guards are not independent controls.
The default `governed` assurance profile requires that separation. An operator
may explicitly select `internal_functional` for internal testing: record missing
or unverified edit/bypass separation as a production-readiness limitation, not a
functional blocker. Terraform plan policy and all existing platform protections
remain required and unchanged; the agent cannot select this exception itself.

The v4 contract and reference templates remain unchanged for existing pinned
installations. Adopt v5 explicitly through a reviewed immutable library revision.
No automatic customer rollout is part of the internal acceptance work.

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

Existing Terraform roots are extended in place, not overwritten with this
library's scaffold. The scaffold's required filenames apply only to BOOTSTRAP.
The central `contracts/terraform-plan-policy.jq` is the canonical policy shared
by runner validation and the Harness native plan guard. The guard adds a
`capability` input, rejects drift and scopes creates to the selected capability
or approved foundation addresses. Existing-resource updates still require a
separate operator-reviewed migration. Run `python3 scripts/sync-plan-policy.py`
after changing that policy and `--check` to verify the committed template.

## Validation

The native-CI reference can use a different Kubernetes cluster from AWS/EKS CD.
Bind `HARNESS_CI_KUBERNETES_CONNECTOR_REF`, `HARNESS_CI_AWS_CONNECTOR_REF`, and
`HARNESS_CI_DELEGATE_SELECTOR` from the application's optional
`spec.harness.ciKubernetesConnectorRef`, `ciAwsConnectorRef`, and
`ciDelegateSelector`. When omitted, use their existing non-CI counterparts.
The existing runtime build namespace/service account apply to the CI cluster.
Keep Terraform and deployment connectors/selectors unchanged. A non-AWS build
cluster needs a verified ECR identity such as Harness OIDC; it cannot inherit
EKS Pod Identity simply by copying a service account name.

Run `ruby tests/test_permissions_boundary.rb` for the boundary plan policy and
`sh tests/test-root.sh` for offline OpenTofu plans of the root reference with
mocked AWS/Kubernetes providers. These tests do not apply infrastructure or
require cloud credentials. Canonical customer initialization remains in the
[factory onboarding guide](https://github.com/stackgen-demo/autonomous-factory-demo/blob/main/docs/autonomous-factory-portability.md).

Run `ruby tests/test_delivery.rb` for foundation contracts, native-stage ordering,
immutable Terraform checkout, and executable mode-specific plan-guard checks.

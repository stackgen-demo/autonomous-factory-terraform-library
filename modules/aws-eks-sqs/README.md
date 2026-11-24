# EKS application SQS access

The default remains producer-only: `sqs:GetQueueAttributes` and `sqs:SendMessage`
on this module's queue. Set `enable_consumer_access = true` for a worker that also
needs `sqs:ReceiveMessage` and `sqs:DeleteMessage`. No permissions are added for
other queues or the DLQ. The role and EKS Pod Identity association are unchanged.

`kms_key_arn` preserves the deployed baseline's optional customer-managed key on
both the primary queue and DLQ and its key-scoped `kms:Decrypt` and
`kms:GenerateDataKey` permissions. The existing KMS key policy must also permit
that role; this module does not modify external key policies. Omitting the key
preserves the baseline's null configuration; no new encryption default is imposed.
DLQ retention stays at 14 days, redrive at five receives, and visibility at 30 seconds.

## Compatibility and tests

Requires Terraform >= 1.7 (mocked tests) and `hashicorp/aws ~> 5.0`. The module and
`tests/fixtures/checkout` lock AWS 5.100.0, matching the active checkout root.
The old OpenTofu AWS v6 lock entry is replaced; no AWS v6 upgrade is required.

From this directory:

```sh
terraform fmt -check -recursive
terraform init -backend=false -lockfile=readonly
terraform validate
terraform test
checkov -d . --framework terraform
terraform -chdir=tests/fixtures/checkout init -backend=false -lockfile=readonly
terraform -chdir=tests/fixtures/checkout validate
terraform -chdir=tests/fixtures/checkout test
```

All test runs use mocked AWS resources and make no deployment calls. Module tests
assert configured policy-document actions/resources, encryption, DLQ settings,
and identity bindings; they do not claim live IAM authorization or exercise a
real key policy. The fixture verifies the AWS v5 caller contract. STA-400 is a
sandbox rehearsal ending at a draft PR, not an apply or release.

## Checkout worker consumer guard (STA-403)

Set both flags for a checkout worker. `require_consumer_access` is a non-nullable
boolean defaulting to `false`, so existing producer-only and consumer callers
keep their behavior. A resource precondition rejects the combination
`require_consumer_access = true` and `enable_consumer_access = false` during
planning. The module does not infer workload identity: callers must opt in for
checkout workers. This guard checks configuration, not live IAM authorization.

```hcl
module "checkout_worker_queue" {
  source = "./modules/aws-eks-sqs"

  queue_name              = "orders"
  cluster_name            = "checkout-sandbox"
  namespace               = "checkout"
  service_account_name    = "checkout-worker"
  pod_identity_role_arn   = "arn:aws:iam::123456789012:role/checkout-worker"
  enable_consumer_access  = true
  require_consumer_access = true
}
```

The runnable `tests/fixtures/checkout` caller enables both flags with AWS
`~> 5.0`, locked to 5.100.0. Tests cover unchanged producer-only defaults,
consumer access with and without the guard, and the rejected combination using
`expect_failures`. Existing encryption, redrive, DLQ and identity assertions stay
in place. Test `apply` commands use a mocked provider, not an AWS deployment.

Source comparison: `checkout-sqs-baseline-v1.0.0` retains the same optional KMS
key handling, key-scoped IAM permissions, queues, role binding and outputs.
`main` already adds opt-in consumer access and AWS v5 tests; this change keeps
those additions and the deployed settings. No public input or output is removed.

## Targeted Pod Identity consumer guard (STA-406)

The EKS Pod Identity association enforces the same opt-in consumer requirement
as the queue. A plan targeting only
`aws_eks_pod_identity_association.application` therefore also rejects
`require_consumer_access = true` with `enable_consumer_access = false`, even
though the queue is not in that plan. The queue precondition remains in place.
Producer-only defaults and all valid configurations retain their existing
settings; no inputs, outputs or IAM permissions change.

The mocked AWS v5 module tests retain the existing full-plan rejection case
and add `checkout_consumer_disabled_targeted_association_rejected`, using
`plan_options.target` and expecting the association precondition to fail.
The AWS v5 checkout fixture remains constrained to `~> 5.0` and locked to 5.100.0.
These are configuration checks, not live IAM authorization or a recommendation
to use targeted plans for normal deployments.

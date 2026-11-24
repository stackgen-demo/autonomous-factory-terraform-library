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

## Checkout worker configuration guard

`require_consumer_access` is a non-nullable boolean, defaulting to `false`.
Set it to `true` for a checkout worker to reject a configuration that leaves
`enable_consumer_access = false`. The IAM role policy resource precondition
fails during planning. The guard does not grant permissions itself and cannot
detect live IAM drift; existing consumers and producer-only callers are unchanged.

```hcl
module "checkout" {
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

The existing producer-only, optional consumer, KMS, DLQ and identity tests remain.
Additional tests cover the required-consumer configuration and the rejected
combination. The checkout fixture enables both flags with AWS v5.

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
real key policy. The fixture verifies the AWS v5 caller contract. STA-402 is a
sandbox guard change ending at a draft PR, not an apply or release.

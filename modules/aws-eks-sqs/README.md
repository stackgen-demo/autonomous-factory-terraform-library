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

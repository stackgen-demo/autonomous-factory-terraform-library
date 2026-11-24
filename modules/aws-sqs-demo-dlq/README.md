# AWS SQS sandbox dead-letter queue

Reusable **standard** SQS dead-letter queue, encrypted at rest with an existing
customer-managed KMS key. Defaults to 14-day message retention. Includes a queue
policy denying non-TLS requests; it grants no queue access. No AWS resources have
been deployed by this implementation stage.

## Requirements

- Terraform >= 1.7.0 (mock-provider tests require 1.7+).
- `hashicorp/aws ~> 5.0`; the compatibility fixture and minimal example pin
  **5.100.0**, matching the checkout AppStack lock. No AWS v6 upgrade is required.
- An existing, enabled customer-managed symmetric encryption KMS key in the
  queue's AWS region. ARN validation rejects aliases and bare key IDs, but cannot
  verify key ownership, state, region or policy offline.

## Usage

```hcl
module "checkout_dlq" {
  source = "./modules/aws-sqs-demo-dlq"

  queue_name  = "checkout-sandbox-dlq"
  kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  tags = {
    Environment = "sandbox"
    Service     = "checkout"
  }
}
```

`examples/minimal` is a standalone consumer example; provide `queue_name` and
`kms_key_arn`. The module inherits the caller's AWS provider and region. The
example explicitly selects `us-west-2`; it is not a deployment instruction.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `queue_name` | `string` | required | 1-80 letters, digits, hyphens or underscores; standard queues only |
| `kms_key_arn` | `string` | required | Customer-managed KMS key ARN, not alias ARN or bare key ID |
| `message_retention_seconds` | `number` | `1209600` | Integer from 60 to 1209600; 14 days by default |
| `tags` | `map(string)` | `{}` | Queue tags, in addition to provider default tags |

## Outputs

| Name | Description |
| --- | --- |
| `queue_arn` | Queue ARN for a source queue's `deadLetterTargetArn` |
| `queue_url` | Queue URL |

## Integration boundaries

This module does not create a source queue, KMS key, IAM grants or redrive policy.
The source queue owner must configure `redrive_policy` using `queue_arn` and a
suitable `maxReceiveCount`. Keep DLQ retention longer than source-queue retention:
standard queues retain the original enqueue timestamp when messages are moved.
SQS defaults to allowing same-account, same-region source queues to use this DLQ;
this module does not narrow that default with a redrive allow policy. Scope source
queues and permissions in the consumer when needed. Only standard source queues
are supported; FIFO requires a separate design.

The caller owns KMS key policy and producer/consumer/redrive IAM permissions.
Redrive may require decrypt permissions for source and DLQ keys and encrypt/data
key permissions for the destination. The TLS deny statement does not replace
identity policies or KMS permissions. Changing names or encryption settings can
have service/replacement implications; review an actual plan before deployment.

## Offline checks (no apply against AWS)

Run from this module directory on the runner:

```sh
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
terraform test -no-color
checkov --version  # must report 3.2.500
checkov --directory . --framework terraform
```

Also initialize and validate `examples/minimal` and `tests/fixtures/aws-v5`
with `-backend=false -input=false`. The fixture's exact AWS 5.100.0 requirement
constrains the provider used by the root module's test initialization. Inspect
the resulting lock selection during validation. All test providers are mocked,
including `command = apply` runs: they never create real AWS resources. Do not run
an unmocked apply. The suite covers encryption, retention defaults and overrides,
tags, outputs, TLS policy, invalid inputs and the pinned AWS v5 consumer fixture.

These are commands to run, **not validation results**. Required evidence is
formatting, backend-free validation, mocked tests and stock Terraform-framework
Checkov **3.2.500**, all on the exact candidate commit. No checks are skipped or
suppressed. This stage makes no claim that these checks have passed.

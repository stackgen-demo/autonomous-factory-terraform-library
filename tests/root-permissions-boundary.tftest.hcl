# Offline plans only. Mocked providers never contact AWS or Kubernetes.
mock_provider "aws" {
  mock_data "aws_eks_cluster" {
    defaults = {
      endpoint              = "https://example.invalid"
      certificate_authority = [{ data = "dGVzdA==" }]
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}
mock_provider "kubernetes" {}

variables {
  application_name     = "boundary-test"
  aws_region           = "us-west-2"
  cluster_name         = "boundary-test"
  namespace            = "boundary-test"
  service_account_name = "application"
}

run "legacy_optional" {
  command = plan
  assert {
    condition     = aws_iam_role.application.permissions_boundary == null
    error_message = "Omitted boundary must leave the old role behavior unchanged."
  }
}

run "configured_boundary" {
  command = plan
  variables {
    permissions_boundary_arn = "arn:aws:iam::123456789012:policy/platform/application-boundary"
  }
  assert {
    condition     = aws_iam_role.application.permissions_boundary == var.permissions_boundary_arn
    error_message = "The exact approved ARN must reach the application's IAM role."
  }
}

run "invalid_policy_reference" {
  command = plan
  variables {
    permissions_boundary_arn = "arn:aws:iam::123456789012:role/not-a-policy"
  }
  expect_failures = [var.permissions_boundary_arn]
}

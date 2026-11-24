mock_provider "aws" {
  # Supply syntactically valid mock JSON; policy assertions inspect configured statements.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-west-2:123456789012:orders"
    }
  }
}

run "checkout_aws_v5" {
  command = apply
  assert {
    condition     = output.queue_arn == "arn:aws:sqs:us-west-2:123456789012:orders"
    error_message = "The AWS v5 checkout fixture must expose the orders queue ARN."
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  tags              = var.tags
}

data "aws_iam_policy_document" "application_log_write" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }
}

resource "aws_iam_role_policy" "application_log_write" {
  name   = "${replace(var.log_group_name, "/", "-")}-write"
  role   = element(reverse(split("/", var.pod_identity_role_arn)), 0)
  policy = data.aws_iam_policy_document.application_log_write.json
}

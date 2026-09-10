resource "aws_sns_topic" "this" {
  name = var.topic_name
  tags = var.tags
}

data "aws_iam_policy_document" "application_topic_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_iam_role_policy" "application_topic_publish" {
  name   = "${var.topic_name}-publish"
  role   = element(reverse(split("/", var.pod_identity_role_arn)), 0)
  policy = data.aws_iam_policy_document.application_topic_publish.json
}

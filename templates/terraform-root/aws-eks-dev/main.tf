resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "autonomous-factory-demo"
      environment                 = "dev"
    }
  }
}

resource "kubernetes_service_account_v1" "application" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
  }
}

resource "aws_ecr_repository" "application" {
  name                 = "autonomous-factory-demo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application" {
  name               = "autonomous-factory-demo-dev"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

module "orders_queue" {
  source = "git::https://github.com/stackgen-demo/autonomous-factory-terraform-library.git//modules/aws-eks-sqs?ref=v1.0.0"

  queue_name            = "autonomous-factory-orders-dev"
  cluster_name          = var.cluster_name
  namespace             = kubernetes_namespace_v1.application.metadata[0].name
  service_account_name  = kubernetes_service_account_v1.application.metadata[0].name
  pod_identity_role_arn = aws_iam_role.application.arn
  tags = {
    application = "autonomous-factory-demo"
    environment = "dev"
    managed_by  = "aiden"
  }
}

output "orders_queue_url" {
  value = module.orders_queue.queue_url
}

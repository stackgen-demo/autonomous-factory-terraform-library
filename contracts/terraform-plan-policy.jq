# factory-plan-policy-v1: used unchanged by the runner and native Harness guard.
def capability_prefix:
  {"aws-eks-cloudwatch-logs":"module.audit_log_group.",
   "aws-eks-sns":"module.events_topic.",
   "aws-eks-sqs":"module.orders_queue."}[$capability];
def approved_create:
  .address as $address
  | (["aws_ecr_repository.application", "aws_iam_role.application",
      "kubernetes_namespace_v1.application", "kubernetes_service_account_v1.application"]
     | index($address)) != null
    or (capability_prefix as $prefix | $prefix != null and ($address | startswith($prefix)));
(.errored != true) and (.complete != false)
and all(.resource_drift[]?; .change.actions == ["no-op"])
and (
  if $mode == "CODE_ONLY" or $mode == "DELIVERY_BOOTSTRAP" then
    $capability == "none"
    and all(.resource_changes[]?; .change.actions == ["no-op"] or .change.actions == ["read"])
  elif $mode == "FOUNDATION_BOOTSTRAP" or $mode == "INFRA_CHANGE" then
    (if $mode == "FOUNDATION_BOOTSTRAP" then $capability == "none" else capability_prefix != null end)
    and all(.resource_changes[]?;
      .change.actions == ["no-op"] or .change.actions == ["read"]
      or (.change.actions == ["create"] and approved_create))
  else false end
)

# jq -e --arg boundary <approved ARN or empty> --arg account <AWS account> -f FILE PLAN.json
# Only checks evidence. Never renders HCL, changes state, or attaches a policy.
def require($ok; $reason): if $ok then . else error($reason) end;
def boundary_value: if . == null then "" else . end;
. as $plan
| require(($plan | type) == "object" and ($plan.resource_changes | type) == "array";
          "missing Terraform resource-change evidence")
| require(($plan.errored // false) == false and $plan.complete != false;
          "incomplete or errored Terraform plan")
| require($boundary == "" or
          (($boundary | test("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:policy/[A-Za-z0-9+=,.@_-]+(/[A-Za-z0-9+=,.@_-]+)*$")) and
           ($boundary | split(":")[4]) == $account);
          "boundary must be an approved customer policy in the application account")
| [$plan.resource_changes[] | select(.mode == "managed" and .type == "aws_iam_role")] as $roles
| require($boundary == "" or
          ([$roles[] | select(.address == "aws_iam_role.application")] | length) == 1;
          "configured boundary requires the application IAM role in the plan")
| require(all($roles[];
    (.change.actions == ["create"] or .change.actions == ["no-op"]) and
    (.change.after | type) == "object" and
    (.change.after_unknown.permissions_boundary // false) == false and
    (if $boundary != "" then .change.after.permissions_boundary == $boundary
     elif .change.actions == ["create"] then (.change.after.permissions_boundary | boundary_value) == ""
     else true end) and
    (if .change.before != null then
       (.change.before.permissions_boundary | boundary_value) == (.change.after.permissions_boundary | boundary_value)
     else true end));
    "IAM role boundary is missing, unknown, changed, removed, or differs from the approved ARN")
| true

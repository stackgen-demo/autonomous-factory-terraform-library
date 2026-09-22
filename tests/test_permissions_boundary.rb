require "json"
require "minitest/autorun"
require "open3"

class PermissionsBoundaryTest < Minitest::Test
  POLICY = File.expand_path("../contracts/permissions-boundary-plan.jq", __dir__)
  ACCOUNT = "123456789012"
  ARN = "arn:aws:iam::#{ACCOUNT}:policy/platform/application-boundary"

  def role(boundary, before: nil, actions: ["create"], unknown: false, address: "aws_iam_role.application")
    {address: address, mode: "managed", type: "aws_iam_role", change: {
      actions: actions, before: before, after: {name: "example-dev", permissions_boundary: boundary},
      after_unknown: {permissions_boundary: unknown}}}
  end

  def check(resources, boundary: ARN, extra: {})
    Open3.capture3("jq", "-e", "--arg", "boundary", boundary, "--arg", "account", ACCOUNT,
                   "-f", POLICY, stdin_data: JSON.generate({resource_changes: resources}.merge(extra)))
  end

  def test_bootstrap_optional_and_configured
    assert check([role(nil)], boundary: "")[2].success?
    assert check([role(ARN)])[2].success?
    refute check([role(ARN)], boundary: "")[2].success?, "Agent must not choose an unconfigured boundary"
  end

  def test_exact_boundary_required_on_every_role
    [nil, "", ARN + "-other", ARN.sub(ACCOUNT, "999999999999")].each do |wrong|
      refute check([role(wrong)])[2].success?, wrong.inspect
    end
    refute check([role(ARN), role(nil, address: "module.feature.aws_iam_role.extra")])[2].success?
    refute check([role(ARN, unknown: true)])[2].success?
    refute check([])[2].success?
  end

  def test_extend_preserves_existing_boundary
    old = {name: "example-dev", permissions_boundary: ARN}
    assert check([role(ARN, before: old, actions: ["no-op"])])[2].success?
    assert check([role(ARN, before: old, actions: ["no-op"])], boundary: "")[2].success?
    assert check([role(nil, before: {name: "example-dev"}, actions: ["no-op"])], boundary: "")[2].success?
    [nil, ARN + "-other"].each do |wrong|
      refute check([role(wrong, before: old, actions: ["no-op"])], boundary: "")[2].success?
    end
    refute check([role(nil, before: {name: "example-dev"}, actions: ["no-op"])])[2].success?
  end

  def test_invalid_configuration_and_plans_fail_closed
    ["*", " ", "arn:aws:iam::#{ACCOUNT}:role/test", ARN.sub(ACCOUNT, "999999999999")].each do |bad|
      refute check([role(bad)], boundary: bad)[2].success?
    end
    [{complete: false}, {errored: true}, {resource_changes: nil}].each do |bad|
      refute check([role(ARN)], extra: bad)[2].success?
    end
    [["update"], ["delete"], ["delete", "create"]].each do |actions|
      refute check([role(ARN, actions: actions)])[2].success?
    end
  end
end

require "minitest/autorun"
require "yaml"
require "json"
require "tempfile"
require "open3"

class DeliveryContractTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  def test_foundation_without_cloud_capability
    schema = JSON.parse(File.read(File.join(ROOT, "contracts/application-factory-v1.schema.json")))
    assert_equal 0, schema.dig("properties", "spec", "properties", "eligibleCapabilities", "minItems")
    contract = JSON.parse(File.read(File.join(ROOT, "contracts/autonomous-factory-v4.json")))
    assert_equal false, contract.dig("foundation", "capabilityRequired")
    assert_equal %w[NO_CHANGE CHANGE_REQUIRED BLOCKED], contract.fetch("dependencyDecision").keys
    model = YAML.load_stream(File.read(File.join(ROOT, contract.dig("foundation", "systemModelTemplate"))))
    assert_equal %w[System Component], model.map { |entity| entity.fetch("kind") }
  end

  def test_native_pipeline_order_and_zero_change_guard
    pipeline = YAML.safe_load(File.read(File.join(ROOT, "templates/harness/aws-eks-dev-pipeline-v2.yaml.tftpl"))).fetch("pipeline")
    stages = pipeline.fetch("stages").map { |item| item.fetch("stage") }
    assert_equal %w[terraform_provisioning build_and_publish deploy_to_dev], stages.map { |s| s.fetch("identifier") }
    assert stages.all? { |stage| stage.fetch("failureStrategies").length == 1 }
    steps = stages.first.dig("spec", "execution", "steps").map { |s| s.fetch("step") }
    assert_equal %w[TerraformPlan ShellScript TerraformApply], steps.map { |s| s.fetch("type") }
    config = steps.first.dig("spec", "configuration")
    assert_equal false, config.fetch("skipRefreshCommand")
    assert_equal true, config.fetch("exportTerraformPlanJson")
    assert_equal "Commit", config.dig("configFiles", "store", "spec", "gitFetchType")
    assert_equal "<+pipeline.variables.commit_sha>", config.dig("configFiles", "store", "spec", "commitId")
    Tempfile.create("factory-plan") do |plan|
      script = steps[1].dig("spec", "source", "spec", "script").sub("<+execution.steps.terraform_plan.plan.jsonFilePath>", plan.path)
      %w[CODE_ONLY DELIVERY_BOOTSTRAP FOUNDATION_BOOTSTRAP INFRA_CHANGE unknown].each do |mode|
        [["no-op"], ["read"], ["create"], ["update"], ["delete"], ["delete", "create"]].each do |actions|
          plan.rewind
          plan.truncate(0)
          plan.write(JSON.generate(resource_changes: [{change: {actions: actions}}]))
          plan.flush
          _, _, status = Open3.capture3({"DELIVERY_MODE" => mode}, "bash", "-c", script)
          allowed = mode != "unknown" && ([%w[no-op], %w[read]].include?(actions) || (actions == ["create"] && %w[FOUNDATION_BOOTSTRAP INFRA_CHANGE].include?(mode)))
          assert_equal allowed, status.success?, "#{mode}: #{actions}"
        end
      end
    end
  end
end

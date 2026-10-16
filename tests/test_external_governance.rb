require 'json'
require 'yaml'
require 'minitest/autorun'

class ExternalGovernanceTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  def test_external_governance_keeps_native_delivery_and_legacy_contract
    current = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v6.json')))
    legacy = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v5.json')))
    %w[applicationContract dependencyDecision foundation capabilities systemModel].each do |key|
      assert_equal legacy.fetch(key), current.fetch(key)
    end
    delivery = current.fetch('deliveryPipeline')
    assert_includes delivery.fetch('governance'), 'External OPA/platform governance'
    refute delivery.key?('planGuard')
    refute delivery.key?('planPolicyPath')
    refute current.fetch('validation').key?('defaultPlanPolicy')
    template = File.read(File.join(ROOT, delivery.fetch('template')))
    pipeline = YAML.safe_load(template).fetch('pipeline')
    steps = pipeline.fetch('stages').flat_map { |s| s.dig('stage', 'spec', 'execution', 'steps') || [] }.map { |s| s.fetch('step') }
    %w[TerraformPlan TerraformApply K8sRollingDeploy].each { |type| assert steps.any? { |s| s['type'] == type }, type }
    refute_match(/terraform_plan_guard|TERRAFORM_PLAN_POLICY|\bjq\b|FACTORY PLAN POLICY/, template)
    plan = steps.find { |s| s['type'] == 'TerraformPlan' }
    apply = steps.find { |s| s['type'] == 'TerraformApply' }
    assert_equal false, plan.dig('spec', 'configuration', 'skipRefreshCommand')
    assert_equal 'InheritFromPlan', apply.dig('spec', 'configuration', 'type')
    assert_equal plan.dig('spec', 'provisionerIdentifier'), apply.dig('spec', 'provisionerIdentifier')
    assert_operator steps.index(plan), :<, steps.index(apply)
  end
end

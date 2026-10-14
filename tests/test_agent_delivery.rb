require 'json'
require 'digest'
require 'minitest/autorun'

class AgentDeliveryContractTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  V4 = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v4.json')))
  V5 = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v5.json')))

  def test_preserves_capabilities_and_infrastructure_policy
    %w[applicationContract dependencyDecision foundation capabilities systemModel terraformRoot validation].each do |key|
      assert_equal V4.fetch(key), V5.fetch(key), key
    end
    assert_equal V4['deliveryPipeline']['planPolicyPath'], V5['deliveryPipeline']['planPolicyPath']
  end

  def test_no_template_identifiers_or_required_input_names
    delivery = V5.fetch('deliveryPipeline')
    refute delivery.key?('requiredStageIdentifiers')
    assert_equal %w[TerraformPlan TerraformApply K8sRollingDeploy], delivery.fetch('requiredNativeStepTypes')
    assert_includes delivery.fetch('compatibility'), 'Discover actual node paths and input bindings'
    assert_includes delivery.fetch('ordering'), 'Build may precede Terraform'
    assert_includes delivery.fetch('immutableRevision'), 'equivalent immutable input bindings'
  end

  def test_retains_safety_and_uncertain_write_reconciliation
    delivery = V5.fetch('deliveryPipeline')
    assert_includes delivery.fetch('planGuard'), 'replacements/deletes block'
    assert_includes delivery.fetch('planGuard'), 'zero resource changes'
    assert_includes delivery.fetch('monitoring'), 'never blind retry'
    assert_includes delivery.fetch('enforcement'), 'not independent authorization boundaries'
    assert_includes delivery.fetch('existingResources'), 'scoped reviewed correction'
  end
end

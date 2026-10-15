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

  def test_explicit_internal_assurance_does_not_change_plan_policy
    profiles = V5.fetch('assuranceProfiles')
    assert_equal 'governed', profiles.fetch('default')
    assert_equal true, profiles.dig('governed', 'requireIndependentEnforcement')
    assert_equal false, profiles.dig('internal_functional', 'requireIndependentEnforcement')
    assert_includes profiles.dig('internal_functional', 'scope'), 'All Terraform plan rules'
    assert_includes profiles.dig('internal_functional', 'scope'), 'Do not disable or bypass existing controls'
    assert_includes V5.dig('deliveryPipeline', 'enforcement'), 'never through application code'
    assert_equal V4.fetch('validation'), V5.fetch('validation')
  end
end

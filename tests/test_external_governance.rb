require 'json'
require 'yaml'
require 'minitest/autorun'

class ExternalGovernanceTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  def test_completion_uses_pipeline_status_without_changing_pipeline_checks
    current = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v6.json')))
    delivery = current.fetch('deliveryPipeline')
    assert_equal 'harness-pipeline-terminal-status', delivery.fetch('successCriterion')
    assert_includes delivery.fetch('monitoring'), 'poll only that execution'
    assert_includes delivery.fetch('monitoring'), 'never blind retry'
    assert_includes delivery.fetch('monitoring'), 'INCOMPLETE'
    assert_includes delivery.fetch('completionReporting'), 'does not independently inspect'
    assert_includes delivery.fetch('completionReporting'), 'Preserve pipeline checks'
    assert_equal %w[TerraformPlan TerraformApply K8sRollingDeploy], delivery.fetch('requiredNativeStepTypes')
  end

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

  def test_reference_uses_native_ci_not_a_build_job_script
    contract = JSON.parse(File.read(File.join(ROOT, 'contracts/autonomous-factory-v6.json')))
    template = File.read(File.join(ROOT, contract.dig('deliveryPipeline', 'template')))
    pipeline = YAML.safe_load(template).fetch('pipeline')
    stages = pipeline.fetch('stages').map { |s| s.fetch('stage') }
    assert_equal %w[Custom CI Deployment], stages.map { |s| s.fetch('type') }
    ci = stages[1].fetch('spec')
    assert_equal true, ci.fetch('cloneCodebase')
    assert_equal 'KubernetesDirect', ci.dig('infrastructure', 'type')
    assert_equal '__BUILD_SERVICE_ACCOUNT__', ci.dig('infrastructure', 'spec', 'serviceAccountName')
    assert_equal %w[Run BuildAndPushECR], ci.dig('execution', 'steps').map { |s| s.dig('step', 'type') }
    assert_equal '__HARNESS_IMAGE_REGISTRY_CONNECTOR_REF__', ci.dig('execution', 'steps', 0, 'step', 'spec', 'connectorRef')
    assert_equal 'commitSha', pipeline.dig('properties', 'ci', 'codebase', 'build', 'type')
    assert_equal '<+pipeline.variables.commit_sha>', pipeline.dig('properties', 'ci', 'codebase', 'build', 'spec', 'commitSha')
    build = ci.dig('execution', 'steps', 1, 'step', 'spec')
    assert_equal ['<+pipeline.variables.commit_sha>'], build.fetch('tags')
    assert_equal '__HARNESS_CI_AWS_CONNECTOR_REF__', build.fetch('connectorRef')
    assert_equal '__HARNESS_CI_KUBERNETES_CONNECTOR_REF__', ci.dig('infrastructure', 'spec', 'connectorRef')
    assert_equal ['__HARNESS_CI_DELEGATE_SELECTOR__'], stages[1].fetch('delegateSelectors')
    assert_equal ['__HARNESS_DELEGATE_SELECTOR__'], stages[0].dig('spec', 'execution', 'steps', 0, 'step', 'spec', 'delegateSelectors')
    refute_match(/ShellScript|kubectl|kind: Job|GITHUB_TOKEN|kaniko-project/, template)
    stages.each { |s| assert_equal 'MarkAsFailure', s.dig('failureStrategies', 0, 'onFailure', 'action', 'type') }
    assert_includes contract.dig('deliveryPipeline', 'referenceUse'), 'copy this pinned YAML'
    schema = JSON.parse(File.read(File.join(ROOT, 'contracts/application-factory-v1.schema.json')))
    refute_includes schema.dig('properties', 'spec', 'properties', 'runtime', 'required'), 'githubTokenSecret'
    harness = schema.dig('properties', 'spec', 'properties', 'harness')
    %w[ciKubernetesConnectorRef ciAwsConnectorRef ciDelegateSelector].each do |name|
      assert harness.fetch('properties').key?(name)
      refute_includes harness.fetch('required'), name
    end
  end
end

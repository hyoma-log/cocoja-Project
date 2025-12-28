RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # テスト環境のメール設定
  config.before(:suite) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
    ActionMailer::Base.deliveries.clear
  end
end

require "test_helper"

class I18nNbCoverageTest < ActiveSupport::TestCase
  # Critical view directories that MUST have nb.yml for INFRA-04
  CRITICAL_VIEW_DIRS = %w[
    config/locales/views/budgets
    config/locales/views/enable_banking_items
    config/locales/views/components
    config/locales/views/recurring_transactions
    config/locales/views/reports
    config/locales/models/category
  ].freeze

  CRITICAL_VIEW_DIRS.each do |dir|
    test "#{dir} has nb.yml translation file" do
      nb_path = Rails.root.join(dir, "nb.yml")
      assert File.exist?(nb_path), "Missing Norwegian translation: #{dir}/nb.yml"
    end
  end

  test "application.rb sets default locale to nb" do
    assert_equal :nb, I18n.default_locale, "Default locale should be :nb, got #{I18n.default_locale}"
  end

  test "nb is in available locales" do
    assert_includes I18n.available_locales, :nb, "Norwegian (nb) must be in available_locales"
  end
end

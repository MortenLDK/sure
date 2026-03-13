require "test_helper"
require_relative "../../db/seeds/kirkvik_categories"

class KirkvikCategorySeedTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
    # Clean any existing Kirkvik categories to isolate test
    @family.categories.where(name: KirkvikCategories::CATEGORIES.map { |c| c[:name] }).destroy_all
  end

  test "seeds 6 parent categories" do
    KirkvikCategories.seed!(@family)
    parents = @family.categories.where(parent_id: nil).where(name: KirkvikCategories::CATEGORIES.map { |c| c[:name] })
    assert_equal 6, parents.count
  end

  test "seeds correct parent category names" do
    KirkvikCategories.seed!(@family)
    expected_names = KirkvikCategories::CATEGORIES.map { |c| c[:name] }.sort
    actual_names = @family.categories.where(parent_id: nil)
                          .where(name: expected_names)
                          .pluck(:name).sort
    assert_equal expected_names, actual_names
  end

  test "seeds 31 subcategories total" do
    KirkvikCategories.seed!(@family)
    parent_ids = @family.categories.where(parent_id: nil)
                        .where(name: KirkvikCategories::CATEGORIES.map { |c| c[:name] })
                        .pluck(:id)
    children = @family.categories.where(parent_id: parent_ids)
    assert_equal 31, children.count
  end

  test "is idempotent — running twice produces same count" do
    KirkvikCategories.seed!(@family)
    first_count = @family.categories.count

    KirkvikCategories.seed!(@family)
    second_count = @family.categories.count

    assert_equal first_count, second_count
  end

  test "all parent categories are classified as expense" do
    KirkvikCategories.seed!(@family)
    classifications = @family.categories.where(parent_id: nil)
                             .where(name: KirkvikCategories::CATEGORIES.map { |c| c[:name] })
                             .pluck(:classification).uniq
    assert_equal ["expense"], classifications
  end
end

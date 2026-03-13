# frozen_string_literal: true

# Provides: rails kirkvik:seed
# Run via Kamal: kamal app exec --interactive 'rails kirkvik:seed'
# Run via local: docker compose exec web rails kirkvik:seed

namespace :kirkvik do
  desc "Seed Kirkvik budget categories (6 parents + subcategories) for the first family"
  task seed: :environment do
    require_relative "../../db/seeds/kirkvik_categories"

    family = Family.first
    abort "No family found. Register an account first." unless family

    # Clean up phantom/misnamed categories from prior seeds (idempotent — safe to re-run)
    phantom_helse_count = family.categories
      .where(name: "Helse", parent_id: nil)
      .where.not(id: family.categories.where.not(parent_id: nil).select(:parent_id))
      .destroy_all.length
    phantom_utdanning_count = family.categories
      .where(name: "Utdanning", parent_id: nil)
      .destroy_all.length
    kollektiv_renamed = family.categories
      .where(name: "Kollektivtransport")
      .update_all(name: "Transport")
    helseutgifter_renamed = family.categories
      .where(name: "Helseutgifter")
      .update_all(name: "Helse")

    cleanup_done = phantom_helse_count + phantom_utdanning_count + kollektiv_renamed + helseutgifter_renamed
    if cleanup_done > 0
      puts "Cleanup: removed #{phantom_helse_count} phantom Helse parent(s), #{phantom_utdanning_count} phantom Utdanning parent(s), renamed #{kollektiv_renamed} Kollektivtransport → Transport, renamed #{helseutgifter_renamed} Helseutgifter → Helse"
    else
      puts "Cleanup: nothing to fix (already clean)"
    end

    KirkvikCategories.seed!(family)

    parent_count = family.categories.where(parent_id: nil).count
    child_count = family.categories.where.not(parent_id: nil).count
    puts "Kirkvik categories seeded:"
    puts "  #{parent_count} parent categories"
    puts "  #{child_count} subcategories"
    puts "  #{parent_count + child_count} total"
    puts ""

    family.categories.where(parent_id: nil).order(:name).each do |parent|
      children = family.categories.where(parent_id: parent.id).order(:name)
      puts "  #{parent.lucide_icon} #{parent.name} (#{parent.color})"
      children.each { |c| puts "    - #{c.name}" }
    end

    puts "\nDone. Categories ready."
  end
end

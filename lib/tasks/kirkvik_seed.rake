# frozen_string_literal: true

# Provides: rails kirkvik:seed
# Run via Kamal: kamal app exec --interactive 'rails kirkvik:seed'
# Run via local: docker compose exec web rails kirkvik:seed

namespace :kirkvik do
  desc "Seed Kirkvik budget categories (8 parents + subcategories) for the first family"
  task seed: :environment do
    require_relative "../../db/seeds/kirkvik_categories"

    family = Family.first
    abort "No family found. Register an account first." unless family

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

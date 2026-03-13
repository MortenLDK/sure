# frozen_string_literal: true

# Kirkvik family budget categories — seeded from Hjemme budsjett.xlsx structure
#
# 8 parent categories with 31 subcategories total.
# Norwegian Bokmål names with proper UTF-8 characters.
#
# Usage:
#   KirkvikCategories.seed!(family)
#
# Run via Kamal: kamal app exec --interactive 'rails kirkvik:seed'
# Run via local: docker compose exec web rails kirkvik:seed

module KirkvikCategories
  CATEGORIES = [
    {
      name: "Bolig & Lån",
      color: "#b45309",
      icon: "home",
      classification: "expense",
      subcategories: [
        "Lånerente",
        "Avdrag",
        "Renovering",
        "Kommunale avgifter",
        "Strøm",
        "Starlink Internet",
        "Forsikring",
        "Barnehage",
        "Studier og årsavgift",
        "Utgift arbeidsgiver + briller"
      ]
    },
    {
      name: "Mat & Daglig",
      color: "#f97316",
      icon: "shopping-bag",
      classification: "expense",
      subcategories: [
        "Mat"
      ]
    },
    {
      name: "Transport",
      color: "#0ea5e9",
      icon: "bus",
      classification: "expense",
      subcategories: [
        "Transport",
        "Ryde",
        "Diesel",
        "Ved"
      ]
    },
    {
      name: "Livsstil & Fritid",
      color: "#a855f7",
      icon: "drama",
      classification: "expense",
      subcategories: [
        "Helse",
        "Lunsj",
        "Ferie",
        "Restaurant",
        "Frisør",
        "Klær"
      ]
    },
    {
      name: "Abonnement & Tech",
      color: "#6366f1",
      icon: "wifi",
      classification: "expense",
      subcategories: [
        "Abonnement"
      ]
    },
    {
      name: "Gaver & Annet",
      color: "#61c9ea",
      icon: "gift",
      classification: "expense",
      subcategories: [
        "Gaver",
        "Advokat",
        "Parkering",
        "Bading",
        "Bot",
        "Avis",
        "Innkasso",
        "Annet",
        "MORRO"
      ]
    },
    {
      name: "Helse",
      color: "#4da568",
      icon: "stethoscope",
      classification: "expense",
      subcategories: []
    },
    {
      name: "Utdanning",
      color: "#2563eb",
      icon: "graduation-cap",
      classification: "expense",
      subcategories: []
    }
  ].freeze

  # Idempotent seed — safe to run multiple times.
  # Uses find_or_create_by! so re-running produces no duplicates.
  #
  # Note: Subcategories do NOT set color — the Category model's
  # inherit_color_from_parent callback handles color inheritance automatically.
  def self.seed!(family)
    CATEGORIES.each do |cat_data|
      parent = family.categories.find_or_create_by!(name: cat_data[:name]) do |c|
        c.color = cat_data[:color]
        c.lucide_icon = cat_data[:icon]
        c.classification_unused = cat_data[:classification]
      end

      cat_data[:subcategories].each do |sub_name|
        family.categories.find_or_create_by!(name: sub_name, parent: parent) do |c|
          c.classification_unused = cat_data[:classification]
          c.lucide_icon = "tag"
          # Do NOT set color — inherit_color_from_parent callback handles it
        end
      end
    end
  end
end

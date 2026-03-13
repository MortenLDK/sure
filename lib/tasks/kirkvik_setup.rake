# lib/tasks/kirkvik_setup.rake
namespace :kirkvik do
  desc "Configure the Kirkvik family with Norwegian locale, NOK currency, and Europe/Oslo timezone"
  task setup: :environment do
    family = Family.first
    abort "No family found. Register an account first, then run this task." unless family

    family.update!(
      locale: "nb",
      currency: "NOK",
      timezone: "Europe/Oslo",
      date_format: "%d.%m.%Y",
      country: "NO"
    )

    puts "Kirkvik family configured:"
    puts "  Locale:      #{family.locale}"
    puts "  Currency:    #{family.currency}"
    puts "  Timezone:    #{family.timezone}"
    puts "  Date format: #{family.date_format}"
    puts "  Country:     #{family.country}"
    # Set all existing users to Norwegian locale
    updated = family.users.where.not(locale: "nb").update_all(locale: "nb")
    puts "  Users updated: #{updated}" if updated > 0

    puts ""
    puts "Done. Norwegian settings active."
  end
end

require "test_helper"

class KirkvikFamilyLocaleTest < ActiveSupport::TestCase
  test "family can be updated with Norwegian settings" do
    family = families(:dylan_family)

    family.update!(
      locale: "nb",
      currency: "NOK",
      timezone: "Europe/Oslo",
      date_format: "%d.%m.%Y",
      country: "NO"
    )

    family.reload
    assert_equal "nb", family.locale
    assert_equal "NOK", family.currency
    assert_equal "Europe/Oslo", family.timezone
    assert_equal "%d.%m.%Y", family.date_format
    assert_equal "NO", family.country
  end

  test "Norwegian date format produces dd.mm.yyyy" do
    date = Date.new(2026, 3, 12)
    formatted = date.strftime("%d.%m.%Y")
    assert_equal "12.03.2026", formatted
  end
end

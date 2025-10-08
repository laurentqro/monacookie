require "test_helper"

class CookieTest < ActiveSupport::TestCase
  setup do
    @cookie = cookies(:google_analytics)
    @website = websites(:one)
  end

  test "valid cookie" do
    assert @cookie.valid?
  end

  test "invalid without name" do
    @cookie.name = nil
    refute @cookie.valid?
    assert_not_nil @cookie.errors[:name]
  end

  test "invalid without domain" do
    @cookie.domain = nil
    refute @cookie.valid?
    assert_not_nil @cookie.errors[:domain]
  end

  test "invalid without category" do
    @cookie.category = nil
    refute @cookie.valid?
    assert_not_nil @cookie.errors[:category]
  end

  test "name must be unique per website and domain" do
    duplicate = Cookie.new(
      website: @website,
      name: @cookie.name,
      domain: @cookie.domain,
      category: :necessary
    )
    refute duplicate.valid?
    assert_not_nil duplicate.errors[:name]
  end

  test "same name allowed for different domains" do
    cookie = Cookie.new(
      website: @website,
      name: @cookie.name,
      domain: "different.com",
      category: :necessary
    )
    assert cookie.valid?
  end

  test "same name allowed for different websites" do
    other_website = websites(:company_website)
    cookie = Cookie.new(
      website: other_website,
      name: @cookie.name,
      domain: @cookie.domain,
      category: :necessary
    )
    assert cookie.valid?
  end

  test "category enum values" do
    assert_equal [:necessary, :preferences, :statistics, :marketing], Cookie::CATEGORIES
  end

  test "category necessary" do
    cookie = cookies(:session_cookie)
    assert cookie.necessary?
    assert_equal "necessary", cookie.category
  end

  test "category preferences" do
    cookie = cookies(:language_preference)
    assert_equal "preferences", cookie.category
  end

  test "category statistics" do
    assert_equal "statistics", @cookie.category
  end

  test "category marketing" do
    cookie = cookies(:facebook_pixel)
    assert_equal "marketing", cookie.category
  end

  test "necessary? returns true for necessary cookies" do
    cookie = cookies(:session_cookie)
    assert cookie.necessary?
  end

  test "necessary? returns false for non-necessary cookies" do
    refute @cookie.necessary?
  end

  test "requires_consent? returns false for necessary cookies" do
    cookie = cookies(:session_cookie)
    refute cookie.requires_consent?
  end

  test "requires_consent? returns true for non-necessary cookies" do
    assert @cookie.requires_consent?
  end

  test "category_french returns French translation" do
    assert_equal "Nécessaires", cookies(:session_cookie).category_french
    assert_equal "Préférences", cookies(:language_preference).category_french
    assert_equal "Statistiques", @cookie.category_french
    assert_equal "Marketing", cookies(:facebook_pixel).category_french
  end

  test "persistent? returns true for persistent cookies" do
    assert @cookie.persistent?
  end

  test "persistent? returns false for session cookies" do
    cookie = cookies(:session_cookie)
    refute cookie.persistent?
  end

  test "session_cookie? returns true for session cookies" do
    cookie = cookies(:session_cookie)
    assert cookie.session_cookie?
  end

  test "session_cookie? returns false for persistent cookies" do
    refute @cookie.session_cookie?
  end

  test "activate! sets active to true" do
    @cookie.update(active: false)
    assert @cookie.activate!
    assert @cookie.active
  end

  test "deactivate! sets active to false" do
    @cookie.update(active: true)
    assert @cookie.deactivate!
    refute @cookie.active
  end

  test "summary returns formatted string" do
    expected = "_ga (Statistiques) on .example.com"
    assert_equal expected, @cookie.summary
  end

  test "belongs_to website" do
    assert_equal @website, @cookie.website
  end

  test "active scope" do
    active_cookies = Cookie.active
    assert_includes active_cookies, @cookie
    refute_includes active_cookies, cookies(:inactive_cookie)
  end

  test "inactive scope" do
    inactive_cookies = Cookie.inactive
    assert_includes inactive_cookies, cookies(:inactive_cookie)
    refute_includes inactive_cookies, @cookie
  end

  test "by_category scope" do
    statistics_cookies = Cookie.by_category(:statistics)
    assert_includes statistics_cookies, @cookie
    refute_includes statistics_cookies, cookies(:facebook_pixel)
  end

  test "sorted scope orders by category then name" do
    sorted = @website.cookies.sorted.to_a
    assert_equal "PHPSESSID", sorted.first.name  # necessary comes first
    assert_equal "lang", sorted.second.name  # then preferences
    assert_equal "_ga", sorted.third.name  # then statistics
  end

  test "expiry validation accepts valid formats" do
    valid_formats = ["session", "1 day", "30 days", "1 month", "2 months", "1 year", "2 years", "365"]
    valid_formats.each do |format|
      @cookie.expiry = format
      assert @cookie.valid?, "#{format} should be valid"
    end
  end

  test "expiry validation rejects invalid formats" do
    @cookie.expiry = "invalid format"
    refute @cookie.valid?
    assert_not_nil @cookie.errors[:expiry]
  end

  test "default path is slash" do
    cookie = Cookie.new(
      website: @website,
      name: "test",
      domain: "test.com",
      category: :necessary
    )
    cookie.save
    assert_equal "/", cookie.path
  end

  test "default active is true" do
    cookie = Cookie.new(
      website: @website,
      name: "test",
      domain: "test.com",
      category: :necessary
    )
    cookie.save
    assert cookie.active
  end
end

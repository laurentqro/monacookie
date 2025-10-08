require "test_helper"

class WebsiteTest < ActiveSupport::TestCase
  setup do
    @website = websites(:one)
    @account = accounts(:one)
  end

  test "valid website" do
    assert @website.valid?
  end

  test "invalid without url" do
    @website.url = nil
    refute @website.valid?
    assert_not_nil @website.errors[:url]
  end

  test "invalid without domain" do
    @website.domain = nil
    refute @website.valid?
    assert_not_nil @website.errors[:domain]
  end

  test "invalid with malformed url" do
    @website.url = "not-a-url"
    refute @website.valid?
    assert_not_nil @website.errors[:url]
  end

  test "domain must be unique per account" do
    duplicate = Website.new(
      account: @account,
      url: "https://example.com/page",
      domain: @website.domain
    )
    refute duplicate.valid?
    assert_not_nil duplicate.errors[:domain]
  end

  test "same domain allowed for different accounts" do
    other_account = accounts(:two)
    website = Website.new(
      account: other_account,
      url: "https://example.com",
      domain: @website.domain
    )
    assert website.valid?
  end

  test "extracts domain from url automatically" do
    website = Website.new(
      account: @account,
      url: "https://newsite.com/path"
    )
    website.valid?
    assert_equal "newsite.com", website.domain
  end

  test "generates api_key on create" do
    website = Website.create!(
      account: @account,
      url: "https://newsite.com"
    )
    assert_not_nil website.api_key
    assert_equal 64, website.api_key.length
  end

  test "generates verification_token on create" do
    website = Website.create!(
      account: @account,
      url: "https://newsite.com"
    )
    assert_not_nil website.verification_token
    assert_equal 32, website.verification_token.length
  end

  test "api_key is unique" do
    existing_key = @website.api_key
    new_website = Website.new(
      account: @account,
      url: "https://newsite.com",
      domain: "newsite.com",
      api_key: existing_key
    )
    refute new_website.valid?
    assert_not_nil new_website.errors[:api_key]
  end

  test "verified? returns verification status" do
    @website.verified = true
    assert @website.verified?

    @website.verified = false
    refute @website.verified?
  end

  test "verify! marks website as verified" do
    @website.update(verified: false, verification_token: "token123")
    assert @website.verify!
    assert @website.verified?
    assert_nil @website.verification_token
    assert_nil @website.verification_method
  end

  test "schedule_next_scan updates scan times" do
    freeze_time do
      assert @website.schedule_next_scan
      assert_equal Time.current, @website.last_scan_at
      assert_equal Time.current + 1.month, @website.next_scan_at
    end
  end

  test "schedule_next_scan accepts custom interval" do
    freeze_time do
      @website.schedule_next_scan(1.week)
      assert_equal Time.current + 1.week, @website.next_scan_at
    end
  end

  test "needs_scan? returns true when next_scan_at is nil" do
    @website.update(next_scan_at: nil)
    assert @website.needs_scan?
  end

  test "needs_scan? returns true when next_scan_at is in the past" do
    @website.update(next_scan_at: 1.day.ago)
    assert @website.needs_scan?
  end

  test "needs_scan? returns false when next_scan_at is in the future" do
    @website.update(next_scan_at: 1.day.from_now)
    refute @website.needs_scan?
  end

  test "has_many cookies" do
    assert_respond_to @website, :cookies
    assert_includes @website.cookies, cookies(:session_cookie)
  end

  test "has_many consents" do
    assert_respond_to @website, :consents
    assert_includes @website.consents, consents(:accept_all)
  end

  test "destroys dependent cookies when destroyed" do
    cookie_ids = @website.cookies.pluck(:id)
    @website.destroy
    cookie_ids.each do |id|
      assert_nil Cookie.find_by(id: id)
    end
  end

  test "destroys dependent consents when destroyed" do
    consent_ids = @website.consents.pluck(:id)
    @website.destroy
    consent_ids.each do |id|
      assert_nil Consent.find_by(id: id)
    end
  end

  test "active_cookies_count returns count of active cookies" do
    count = @website.cookies.where(active: true).count
    assert_equal count, @website.active_cookies_count
  end

  test "total_consents_count returns total consents" do
    count = @website.consents.count
    assert_equal count, @website.total_consents_count
  end

  test "recent_consents returns consents from last 30 days" do
    recent = @website.recent_consents
    assert_includes recent, consents(:accept_all)
    refute_includes recent, consents(:old_consent)
  end

  test "verified scope" do
    verified_websites = Website.verified
    assert_includes verified_websites, websites(:one)
    refute_includes verified_websites, websites(:unverified)
  end

  test "unverified scope" do
    unverified_websites = Website.unverified
    assert_includes unverified_websites, websites(:unverified)
    refute_includes unverified_websites, websites(:one)
  end

  test "needing_scan scope" do
    needing_scan = Website.needing_scan
    assert_includes needing_scan, websites(:needs_scan)
    refute_includes needing_scan, websites(:one)
  end

end

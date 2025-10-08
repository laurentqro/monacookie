# frozen_string_literal: true

# Represents a customer website that requires cookie consent management
#
# @example
#   website = Website.create!(
#     account: account,
#     url: "https://example.com",
#     domain: "example.com"
#   )
#
class Website < ApplicationRecord
  # Associations
  belongs_to :account
  has_many :cookies, dependent: :destroy
  has_many :consents, dependent: :destroy

  # Validations
  validates :url, presence: true, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL"}
  validates :domain, presence: true, uniqueness: {scope: :account_id}
  validates :api_key, presence: true, uniqueness: true
  validates :verification_method, inclusion: {in: %w[meta_tag dns_txt], allow_nil: true}

  # Callbacks
  before_validation :extract_domain_from_url, if: :url_changed?
  before_validation :generate_api_key, on: :create
  before_validation :generate_verification_token, on: :create

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :needing_scan, -> { where("next_scan_at IS NULL OR next_scan_at <= ?", Time.current) }

  # Returns whether the website has been verified
  #
  # @return [Boolean] True if the website is verified
  def verified?
    verified
  end

  # Marks the website as verified
  #
  # @return [Boolean] True if successfully verified
  def verify!
    update(verified: true, verification_method: nil, verification_token: nil)
  end

  # Schedules the next cookie scan
  #
  # @param interval [ActiveSupport::Duration] Time until next scan (default: 1.month)
  # @return [Boolean] True if successfully scheduled
  def schedule_next_scan(interval = 1.month)
    update(
      last_scan_at: Time.current,
      next_scan_at: Time.current + interval
    )
  end

  # Returns whether a scan is needed
  #
  # @return [Boolean] True if a scan is needed
  def needs_scan?
    next_scan_at.nil? || next_scan_at <= Time.current
  end

  # Returns the number of active cookies
  #
  # @return [Integer] Count of active cookies
  def active_cookies_count
    cookies.where(active: true).count
  end

  # Returns the total number of consents recorded
  #
  # @return [Integer] Count of consents
  def total_consents_count
    consents.count
  end

  # Returns recent consents (last 30 days)
  #
  # @return [ActiveRecord::Relation<Consent>] Recent consents
  def recent_consents
    consents.where("consent_given_at >= ?", 30.days.ago)
  end

  private

  # Extracts domain from URL
  #
  # @return [void]
  def extract_domain_from_url
    return unless url.present?

    uri = URI.parse(url)
    self.domain = uri.host
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end

  # Generates a secure API key
  #
  # @return [void]
  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end

  # Generates a verification token
  #
  # @return [void]
  def generate_verification_token
    self.verification_token ||= SecureRandom.hex(16)
  end
end

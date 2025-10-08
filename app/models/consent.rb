# frozen_string_literal: true

# Represents a visitor's consent choices for cookies
#
# Consent records are audit-ready logs required for APDP compliance
# per Monaco Law 1.565 Article 6. IP addresses are hashed for privacy.
#
# @example
#   consent = Consent.create!(
#     account: account,
#     website: website,
#     visitor_id: "hash123",
#     consent_given_at: Time.current,
#     consent_choices: {
#       necessary: true,
#       preferences: true,
#       statistics: false,
#       marketing: false
#     },
#     consent_method: :banner_customize
#   )
#
class Consent < ApplicationRecord
  # Consent methods per Monaco Law 1.565
  CONSENT_METHODS = [:banner_accept_all, :banner_reject_all, :banner_customize].freeze

  # Data retention per Monaco standard: 12 months + 30 days
  RETENTION_PERIOD = 13.months

  # Associations
  belongs_to :account
  belongs_to :website

  # Enums
  enum :consent_method, CONSENT_METHODS

  # Validations
  validates :visitor_id, presence: true
  validates :consent_given_at, presence: true
  validates :consent_choices, presence: true
  validates :consent_method, presence: true, inclusion: {in: CONSENT_METHODS.map(&:to_s)}
  validates :consent_version, presence: true, numericality: {only_integer: true, greater_than: 0}
  validate :validate_consent_choices_structure

  # Callbacks
  before_validation :set_consent_given_at, on: :create, if: -> { consent_given_at.nil? }
  before_create :hash_ip_address, if: -> { ip_address_hash.nil? && @raw_ip_address.present? }

  # Scopes
  scope :active, -> { where(withdrawn_at: nil) }
  scope :withdrawn, -> { where.not(withdrawn_at: nil) }
  scope :recent, -> { where("consent_given_at >= ?", 30.days.ago) }
  scope :by_visitor, ->(visitor_id) { where(visitor_id: visitor_id) }
  scope :by_method, ->(method) { where(consent_method: method) }
  scope :accepted_all, -> { where(consent_method: :banner_accept_all) }
  scope :rejected_all, -> { where(consent_method: :banner_reject_all) }
  scope :customized, -> { where(consent_method: :banner_customize) }
  scope :for_retention_cleanup, -> { where("consent_given_at < ?", RETENTION_PERIOD.ago) }

  # Virtual attribute for raw IP address (never stored)
  attr_accessor :raw_ip_address

  # Returns whether the consent is still active (not withdrawn)
  #
  # @return [Boolean] True if consent is active
  def active?
    withdrawn_at.nil?
  end

  # Returns whether the consent has been withdrawn
  #
  # @return [Boolean] True if consent is withdrawn
  def withdrawn?
    withdrawn_at.present?
  end

  # Withdraws the consent
  #
  # @return [Boolean] True if successfully withdrawn
  def withdraw!
    update(withdrawn_at: Time.current)
  end

  # Returns whether a specific category was accepted
  #
  # @param category [Symbol, String] The cookie category
  # @return [Boolean] True if category was accepted
  def accepted?(category)
    consent_choices[category.to_s] == true
  end

  # Returns whether a specific category was rejected
  #
  # @param category [Symbol, String] The cookie category
  # @return [Boolean] True if category was rejected
  def rejected?(category)
    !accepted?(category)
  end

  # Returns the consent rate (percentage of categories accepted)
  #
  # @return [Float] Percentage of accepted categories (0-100)
  def consent_rate
    return 0 if consent_choices.empty?

    accepted_count = consent_choices.values.count(true)
    (accepted_count.to_f / consent_choices.size * 100).round(2)
  end

  # Returns whether all categories were accepted
  #
  # @return [Boolean] True if all categories accepted
  def accepted_all?
    consent_choices.values.all? { |v| v == true }
  end

  # Returns whether all categories were rejected
  #
  # @return [Boolean] True if all categories rejected
  def rejected_all?
    consent_choices.values.all? { |v| v == false }
  end

  # Returns a summary of consent choices for display
  #
  # @return [String] Consent summary
  def summary
    accepted_categories = consent_choices.select { |_k, v| v == true }.keys.join(", ")
    accepted_categories.presence || "None"
  end

  # Returns the consent method in French for Monaco compliance
  #
  # @return [String] French method name
  def consent_method_french
    case consent_method
    when "banner_accept_all"
      "Accepter tout"
    when "banner_reject_all"
      "Refuser tout"
    when "banner_customize"
      "Personnaliser"
    else
      consent_method
    end
  end

  # Cleans up old consents per retention policy
  #
  # @return [Integer] Number of consents deleted
  def self.cleanup_old_consents
    for_retention_cleanup.delete_all
  end

  private

  # Sets consent_given_at to current time if not set
  #
  # @return [void]
  def set_consent_given_at
    self.consent_given_at ||= Time.current
  end

  # Hashes the IP address for privacy (PBKDF2)
  #
  # @return [void]
  def hash_ip_address
    return unless @raw_ip_address.present?

    salt = Rails.application.credentials.dig(:ip_salt) || "monacookie_salt"
    self.ip_address_hash = OpenSSL::PKCS5.pbkdf2_hmac(
      @raw_ip_address,
      salt,
      10_000,
      64,
      OpenSSL::Digest::SHA256.new
    ).unpack1("H*")
  end

  # Validates the structure of consent_choices
  #
  # @return [void]
  def validate_consent_choices_structure
    return if consent_choices.blank?

    required_keys = %w[necessary preferences statistics marketing]
    missing_keys = required_keys - consent_choices.keys

    if missing_keys.any?
      errors.add(:consent_choices, "must include all categories: #{missing_keys.join(', ')}")
    end

    consent_choices.each do |key, value|
      unless [true, false].include?(value)
        errors.add(:consent_choices, "#{key} must be true or false")
      end
    end
  end
end

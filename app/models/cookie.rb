# frozen_string_literal: true

# Represents a cookie detected on a customer website
#
# Cookies are categorized according to Monaco Law 1.565:
# - necessary: Essential for site function
# - preferences: User settings, language
# - statistics: Analytics, non-personalized
# - marketing: Advertising, tracking, personalized content
#
# @example
#   cookie = Cookie.create!(
#     website: website,
#     name: "_ga",
#     domain: ".example.com",
#     category: :statistics,
#     description: "Google Analytics tracking cookie"
#   )
#
class Cookie < ApplicationRecord
  # Categories per Monaco Law 1.565 (Article 6)
  CATEGORIES = [:necessary, :preferences, :statistics, :marketing].freeze

  # Associations
  belongs_to :website

  # Enums
  enum :category, CATEGORIES

  # Validations
  validates :name, presence: true
  validates :domain, presence: true
  validates :category, presence: true, inclusion: {in: CATEGORIES.map(&:to_s)}
  validates :name, uniqueness: {scope: [:website_id, :domain]}
  validates :expiry, format: {with: /\A(session|\d+\s*(day|days|month|months|year|years)|\d+)\z/i, allow_blank: true}

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :sorted, -> { order(:category, :name) }

  # Returns whether the cookie is in the necessary category
  #
  # @return [Boolean] True if cookie is necessary
  def necessary?
    category == "necessary"
  end

  # Returns whether the cookie requires consent per Monaco Law 1.565
  #
  # @return [Boolean] True if consent is required (not necessary)
  def requires_consent?
    !necessary?
  end

  # Returns the cookie category in French for Monaco compliance
  #
  # @return [String] French category name
  def category_french
    case category
    when "necessary"
      "Nécessaires"
    when "preferences"
      "Préférences"
    when "statistics"
      "Statistiques"
    when "marketing"
      "Marketing"
    else
      category
    end
  end

  # Returns whether the cookie is persistent (not session)
  #
  # @return [Boolean] True if cookie persists beyond session
  def persistent?
    expiry.present? && expiry.downcase != "session"
  end

  # Returns whether the cookie is a session cookie
  #
  # @return [Boolean] True if cookie is session-based
  def session_cookie?
    !persistent?
  end

  # Activates the cookie
  #
  # @return [Boolean] True if successfully activated
  def activate!
    update(active: true)
  end

  # Deactivates the cookie
  #
  # @return [Boolean] True if successfully deactivated
  def deactivate!
    update(active: false)
  end

  # Returns a summary of the cookie for display
  #
  # @return [String] Cookie summary
  def summary
    "#{name} (#{category_french}) on #{domain}"
  end
end

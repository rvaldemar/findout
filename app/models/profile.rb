class Profile < ApplicationRecord
  belongs_to :user

  # Validations
  validates :user, presence: true
  validates :first_name, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }
  validates :phone, format: { with: /\A[+]?[\d\s()-]+\z/, allow_blank: true }

  # Normalizations
  normalizes :first_name, with: ->(name) { name&.strip&.titleize }
  normalizes :last_name, with: ->(name) { name&.strip&.titleize }
  normalizes :phone, with: ->(phone) { phone&.gsub(/[^\d+]/, "") }

  # Active Storage
  has_one_attached :avatar_image

  # Instance methods
  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end

  def initials
    [first_name&.first, last_name&.first].compact.join.upcase.presence || "?"
  end

  def display_name
    full_name || user.email_address.split("@").first
  end
end

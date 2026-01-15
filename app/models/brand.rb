class Brand < ApplicationRecord
  belongs_to :user

  # Associations
  has_many :experiences, dependent: :destroy
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Active Storage
  has_one_attached :logo_image
  has_one_attached :cover
  has_many_attached :gallery

  # Enums
  enum :status, { draft: 0, pending: 1, active: 2, suspended: 3, archived: 4 }, default: :draft

  # Validations
  validates :name, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # Normalizations
  normalizes :slug, with: ->(slug) { slug&.parameterize }
  normalizes :email, with: ->(e) { e&.strip&.downcase }
  normalizes :website, with: ->(url) { url&.strip&.downcase }

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :verified, -> { where(verified: true) }
  scope :featured, -> { active.verified.order(created_at: :desc) }
  scope :by_location, ->(city) { where(city: city) }
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") }

  # Callbacks
  before_validation :set_slug, on: :create

  # Instance methods
  def average_rating
    reviews.where(status: :approved).average(:rating)&.round(1) || 0
  end

  def total_reviews
    reviews.where(status: :approved).count
  end

  def coordinates
    [latitude, longitude] if latitude.present? && longitude.present?
  end

  def verify!
    update!(verified: true, verified_at: Time.current)
  end

  private

  def set_slug
    self.slug ||= name&.parameterize
  end
end

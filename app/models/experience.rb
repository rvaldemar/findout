class Experience < ApplicationRecord
  belongs_to :brand
  belongs_to :category, optional: true

  # Associations
  has_many :bookings, dependent: :destroy
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Delegate
  delegate :name, to: :brand, prefix: true
  delegate :user, to: :brand

  # Active Storage
  has_one_attached :cover
  has_many_attached :gallery

  # Enums
  enum :status, { draft: 0, pending: 1, active: 2, sold_out: 3, cancelled: 4, archived: 5 }, default: :draft

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :duration_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_participants, numericality: { greater_than: 0 }, allow_nil: true

  # Normalizations
  normalizes :slug, with: ->(slug) { slug&.parameterize }
  normalizes :price_currency, with: ->(c) { c&.upcase || "EUR" }

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :featured, -> { where(featured: true).active }
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(starts_at: :asc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_brand, ->(brand_id) { where(brand_id: brand_id) }
  scope :by_location, ->(city) { where(city: city) }
  scope :price_range, ->(min, max) { where(price_cents: min..max) }
  scope :search, ->(query) { where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") }

  # Callbacks
  before_validation :set_slug, on: :create
  before_validation :set_default_currency

  # Instance methods
  def price
    return nil unless price_cents
    price_cents / 100.0
  end

  def price=(value)
    self.price_cents = (value.to_f * 100).to_i if value.present?
  end

  def formatted_price
    return "Grátis" if price_cents.nil? || price_cents.zero?
    "%.2f #{price_currency}" % price
  end

  def duration_in_hours
    return nil unless duration_minutes
    duration_minutes / 60.0
  end

  def available_spots
    return nil unless capacity
    capacity - bookings.confirmed.sum(:participants)
  end

  def available?
    active? && (capacity.nil? || available_spots&.positive?)
  end

  def average_rating
    reviews.approved.average(:rating)&.round(1) || 0
  end

  def coordinates
    [latitude, longitude] if latitude.present? && longitude.present?
  end

  private

  def set_slug
    self.slug ||= title&.parameterize
  end

  def set_default_currency
    self.price_currency ||= "EUR"
  end
end

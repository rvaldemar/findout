class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :slug, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: ->(name) { name&.strip&.downcase }
  normalizes :slug, with: ->(slug) { slug&.parameterize }

  # Scopes
  scope :ordered, -> { order(name: :asc) }
  scope :popular, -> { left_joins(:taggings).group(:id).order("COUNT(taggings.id) DESC") }

  # Callbacks
  before_validation :set_slug, on: :create

  # Instance methods
  def usage_count
    taggings.count
  end

  # Class methods
  def self.find_or_create_by_name(name)
    find_or_create_by(name: name.strip.downcase) do |tag|
      tag.slug = name.parameterize
    end
  end

  private

  def set_slug
    self.slug ||= name&.parameterize
  end
end

class Category < ApplicationRecord
  # Self-referential associations
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :nullify

  # Other associations
  has_many :experiences, dependent: :nullify
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true

  # Normalizations
  normalizes :slug, with: ->(slug) { slug&.parameterize }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :featured, -> { active.roots.ordered }

  # Callbacks
  before_validation :set_slug, on: :create

  # Instance methods
  def root?
    parent_id.nil?
  end

  def ancestors
    result = []
    current = parent
    while current
      result.unshift(current)
      current = current.parent
    end
    result
  end

  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  private

  def set_slug
    self.slug ||= name&.parameterize
  end
end

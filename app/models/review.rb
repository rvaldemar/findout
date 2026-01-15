class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true

  # Enums
  enum :status, { pending: 0, approved: 1, rejected: 2, flagged: 3 }, default: :pending

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :content, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :title, length: { maximum: 200 }
  validates :user_id, uniqueness: { scope: [:reviewable_type, :reviewable_id], message: "já avaliou este item" }

  # Scopes
  scope :approved, -> { where(status: :approved) }
  scope :pending_moderation, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }
  scope :helpful, -> { order(helpful_count: :desc) }
  scope :for_type, ->(type) { where(reviewable_type: type) }

  # Callbacks
  after_save :update_reviewable_rating, if: :approved?

  # Instance methods
  def approve!
    update!(status: :approved)
  end

  def reject!
    update!(status: :rejected)
  end

  def flag!
    update!(status: :flagged, reported_at: Time.current)
  end

  def mark_helpful!
    increment!(:helpful_count)
  end

  def author_name
    user.profile&.display_name || "Anónimo"
  end

  private

  def update_reviewable_rating
    # Trigger rating recalculation on parent
    reviewable.touch if reviewable.respond_to?(:touch)
  end
end

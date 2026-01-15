class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  # Validations
  validates :notification_type, presence: true
  validates :title, presence: true, length: { maximum: 200 }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }

  # Notification types
  TYPES = %w[
    booking_confirmed
    booking_cancelled
    booking_reminder
    review_received
    review_approved
    favorite_added
    brand_verified
    experience_published
    system_message
  ].freeze

  # Validations
  validates :notification_type, inclusion: { in: TYPES }

  # Instance methods
  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def mark_as_unread!
    update!(read_at: nil)
  end

  # Class methods
  def self.mark_all_as_read!
    unread.update_all(read_at: Time.current)
  end

  def self.create_notification(user:, type:, title:, body: nil, notifiable: nil, data: {})
    create!(
      user: user,
      notification_type: type,
      title: title,
      body: body,
      notifiable: notifiable,
      data: data
    )
  end
end

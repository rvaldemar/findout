class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :experience

  # Delegates
  delegate :brand, :title, to: :experience, prefix: true
  delegate :email_address, to: :user, prefix: true

  # Enums
  enum :status, { pending: 0, confirmed: 1, completed: 2, cancelled: 3, refunded: 4, no_show: 5 }, default: :pending

  # Validations
  validates :participants, presence: true, numericality: { greater_than: 0 }
  validates :scheduled_at, presence: true
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :experience_available, on: :create
  validate :scheduled_in_future, on: :create

  # Normalizations
  normalizes :total_currency, with: ->(c) { c&.upcase || "EUR" }

  # Scopes
  scope :upcoming, -> { confirmed.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :today, -> { where(scheduled_at: Time.current.all_day) }
  scope :this_week, -> { where(scheduled_at: Time.current.all_week) }
  scope :for_experience, ->(experience_id) { where(experience_id: experience_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # Callbacks
  before_validation :calculate_total, on: :create
  after_create :send_confirmation

  # Instance methods
  def total
    return nil unless total_cents
    total_cents / 100.0
  end

  def formatted_total
    return "Grátis" if total_cents.nil? || total_cents.zero?
    "%.2f #{total_currency}" % total
  end

  def confirm!
    update!(status: :confirmed, confirmed_at: Time.current)
  end

  def cancel!
    update!(status: :cancelled, cancelled_at: Time.current)
  end

  def complete!
    update!(status: :completed)
  end

  def can_cancel?
    (pending? || confirmed?) && scheduled_at > 24.hours.from_now
  end

  private

  def calculate_total
    return unless experience&.price_cents
    self.total_cents = experience.price_cents * participants
    self.total_currency = experience.price_currency
  end

  def experience_available
    return unless experience
    unless experience.available?
      errors.add(:experience, "não está disponível")
    end
    if experience.capacity && experience.available_spots.to_i < participants.to_i
      errors.add(:participants, "excede a capacidade disponível")
    end
  end

  def scheduled_in_future
    if scheduled_at.present? && scheduled_at <= Time.current
      errors.add(:scheduled_at, "deve ser no futuro")
    end
  end

  def send_confirmation
    # TODO: Implement notification/email
  end
end

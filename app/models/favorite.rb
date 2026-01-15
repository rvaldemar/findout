class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :favoritable, polymorphic: true

  # Validations
  validates :user_id, uniqueness: { scope: [:favoritable_type, :favoritable_id], message: "já é favorito" }

  # Scopes
  scope :experiences, -> { where(favoritable_type: "Experience") }
  scope :brands, -> { where(favoritable_type: "Brand") }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create :notify_owner

  private

  def notify_owner
    # TODO: Create notification for favoritable owner
  end
end

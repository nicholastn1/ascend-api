class Session < ApplicationRecord
  include BelongsToUser

  before_create :generate_token
  before_create :set_expiry

  validates :token, presence: true, uniqueness: true, on: :update

  scope :active, -> { where("expires_at > ?", Time.current) }

  def active?
    expires_at > Time.current
  end

  def expired?
    !active?
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32)
  end

  def set_expiry
    self.expires_at ||= 30.days.from_now
  end
end

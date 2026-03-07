class Session < ApplicationRecord
  include BelongsToUser

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  validates :token, presence: true, uniqueness: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def active?
    expires_at.present? && expires_at > Time.current
  end

  def expired?
    !active?
  end

  # Authenticate by looking up the token digest for constant-time safety
  def self.find_by_token(raw_token)
    return nil if raw_token.blank?

    token_digest = Digest::SHA256.hexdigest(raw_token)
    find_by(token_digest: token_digest)
  end

  # Return the raw token only at creation time
  attr_reader :raw_token

  private

  def generate_token
    raw = SecureRandom.hex(32)
    @raw_token = raw
    self.token = raw # Keep raw for cookie (will be hashed once migration runs)
    self.token_digest = Digest::SHA256.hexdigest(raw)
  end

  def set_expiry
    self.expires_at ||= 30.days.from_now
  end
end

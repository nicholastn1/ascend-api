class ApiKey < ApplicationRecord
  include BelongsToUser

  validates :key_digest, presence: true, uniqueness: true

  scope :active, -> { where(enabled: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.authenticate(raw_key)
    digest = Digest::SHA256.hexdigest(raw_key)
    key = active.includes(:user).find_by(key_digest: digest)
    return nil unless key

    # Atomic increment to avoid race conditions
    where(id: key.id).update_all([ "request_count = request_count + 1, last_request_at = ?", Time.current ])
    key.user
  end

  def self.generate_key
    raw_key = "ak_#{SecureRandom.hex(24)}"
    digest = Digest::SHA256.hexdigest(raw_key)
    key_start = raw_key[0..7]
    { raw_key: raw_key, digest: digest, key_start: key_start }
  end

  def permissions_array
    JSON.parse(permissions || "[]")
  end

  def permissions_array=(perms)
    self.permissions = perms.to_json
  end
end

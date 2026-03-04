class Passkey < ApplicationRecord
  include BelongsToUser

  validates :credential_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :device_type, presence: true

  def transports_array
    JSON.parse(transports || "[]")
  end

  def transports_array=(values)
    self.transports = values.to_json
  end
end

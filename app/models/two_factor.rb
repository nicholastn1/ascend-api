class TwoFactor < ApplicationRecord
  include BelongsToUser

  encrypts :otp_secret

  def backup_codes_array
    JSON.parse(backup_codes || "[]")
  end

  def backup_codes_array=(codes)
    self.backup_codes = codes.to_json
  end
end

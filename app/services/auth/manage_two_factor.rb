module Auth
  class ManageTwoFactor
    def initialize(user)
      @user = user
    end

    def setup
      secret = ROTP::Base32.random
      two_factor = @user.build_two_factor(otp_secret: secret)
      totp = ROTP::TOTP.new(secret, issuer: "Ascend")
      uri = totp.provisioning_uri(@user.email)

      { secret: secret, uri: uri, two_factor: two_factor }
    end

    def verify_and_enable(code)
      two_factor = @user.two_factor
      raise AuthError, "2FA not set up" unless two_factor

      totp = ROTP::TOTP.new(two_factor.otp_secret, issuer: "Ascend")
      raise AuthError, "Invalid code" unless totp.verify(code, drift_behind: 30)

      backup_codes = generate_backup_codes
      two_factor.update!(backup_codes: backup_codes.to_json)
      @user.update!(two_factor_enabled: true)

      { backup_codes: backup_codes }
    end

    def validate(code)
      two_factor = @user.two_factor
      raise AuthError, "2FA not enabled" unless two_factor

      totp = ROTP::TOTP.new(two_factor.otp_secret, issuer: "Ascend")
      return true if totp.verify(code, drift_behind: 30)

      # Check backup codes
      codes = two_factor.backup_codes_array
      if codes.include?(code)
        codes.delete(code)
        two_factor.update!(backup_codes: codes.to_json)
        return true
      end

      raise AuthError, "Invalid 2FA code"
    end

    def disable
      @user.two_factor&.destroy!
      @user.update!(two_factor_enabled: false)
    end

    private

    def generate_backup_codes
      10.times.map { SecureRandom.hex(4).upcase }
    end
  end
end

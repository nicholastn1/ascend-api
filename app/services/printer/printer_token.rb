module Printer
  class PrinterToken
    TOKEN_TTL = 5.minutes

    class << self
      def generate(resume_id)
        timestamp = (Time.current.to_f * 1000).to_i
        payload = "#{resume_id}:#{timestamp}"
        payload_base64 = Base64.urlsafe_encode64(payload, padding: false)
        signature = OpenSSL::Digest::SHA256.hexdigest("#{payload_base64}.#{auth_secret}")
        "#{payload_base64}.#{signature}"
      end

      def verify(token)
        parts = token.split(".")
        raise "Invalid token format" unless parts.length == 2

        payload_base64, signature = parts

        expected_signature = OpenSSL::Digest::SHA256.hexdigest("#{payload_base64}.#{auth_secret}")
        unless ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
          raise "Invalid token signature"
        end

        payload = Base64.urlsafe_decode64(payload_base64)
        resume_id, timestamp_str = payload.split(":")
        raise "Invalid token payload" unless resume_id.present? && timestamp_str.present?

        timestamp = timestamp_str.to_i
        age_ms = (Time.current.to_f * 1000).to_i - timestamp
        raise "Token expired" if age_ms < 0 || age_ms > TOKEN_TTL.in_milliseconds

        resume_id
      end

      private

      def auth_secret
        ENV.fetch("AUTH_SECRET")
      end
    end
  end
end

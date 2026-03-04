require "rails_helper"

RSpec.describe Printer::PrinterToken do
  around do |example|
    ClimateControl.modify(AUTH_SECRET: "test-secret-key-12345") do
      example.run
    end
  end

  describe ".generate" do
    it "returns a token with payload and signature" do
      token = described_class.generate("resume-123")
      expect(token).to include(".")
      parts = token.split(".")
      expect(parts.length).to eq(2)
    end

    it "encodes the resume_id in the payload" do
      token = described_class.generate("resume-123")
      payload_base64 = token.split(".").first
      payload = Base64.urlsafe_decode64(payload_base64)
      expect(payload).to start_with("resume-123:")
    end
  end

  describe ".verify" do
    it "returns the resume_id for a valid token" do
      token = described_class.generate("resume-123")
      result = described_class.verify(token)
      expect(result).to eq("resume-123")
    end

    it "raises for an invalid signature" do
      token = described_class.generate("resume-123")
      tampered = token.sub(/\..+$/, ".invalidsignature")
      expect { described_class.verify(tampered) }.to raise_error("Invalid token signature")
    end

    it "raises for an invalid format" do
      expect { described_class.verify("no-dot-here") }.to raise_error("Invalid token format")
    end

    it "raises for an expired token" do
      token = nil
      travel_to(10.minutes.ago) { token = described_class.generate("resume-123") }
      expect { described_class.verify(token) }.to raise_error("Token expired")
    end
  end
end

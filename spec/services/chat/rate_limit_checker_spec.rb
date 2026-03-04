require "rails_helper"

RSpec.describe Chat::RateLimitChecker do
  let(:user) { create(:user) }
  let(:checker) { described_class.new(user: user) }

  describe "#usage" do
    it "returns current usage stats" do
      conversation = create(:conversation, user: user)
      create(:message, conversation: conversation, role: "user", created_at: Time.current)

      usage = checker.usage
      expect(usage[:used]).to eq(1)
      expect(usage[:limit]).to eq(50)
      expect(usage[:remaining]).to eq(49)
      expect(usage[:resets_at]).to be_present
    end

    it "only counts today's user messages" do
      conversation = create(:conversation, user: user)
      create(:message, conversation: conversation, role: "user", created_at: 2.days.ago)
      create(:message, conversation: conversation, role: "user", created_at: Time.current)
      create(:message, conversation: conversation, role: "assistant", created_at: Time.current)

      expect(checker.usage[:used]).to eq(1)
    end
  end

  describe "#check!" do
    it "does not raise when within limit" do
      expect { checker.check! }.not_to raise_error
    end

    it "raises when limit exceeded" do
      conversation = create(:conversation, user: user)

      ClimateControl.modify(CHAT_DAILY_LIMIT: "2") do
        3.times { create(:message, conversation: conversation, role: "user") }
        expect {
          described_class.new(user: user).check!
        }.to raise_error(Chat::RateLimitChecker::RateLimitExceeded)
      end
    end
  end
end

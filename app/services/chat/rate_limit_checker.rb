module Chat
  class RateLimitChecker
    DEFAULT_DAILY_LIMIT = 50

    def initialize(user:)
      @user = user
    end

    def check!
      return if within_limit?

      raise RateLimitExceeded, "Daily message limit (#{daily_limit}) reached. Resets at midnight UTC."
    end

    def usage
      {
        used: messages_today,
        limit: daily_limit,
        remaining: [daily_limit - messages_today, 0].max,
        resets_at: Time.current.end_of_day.utc.iso8601
      }
    end

    def within_limit?
      messages_today < daily_limit
    end

    private

    def messages_today
      @messages_today ||= Message
        .joins(:conversation)
        .where(conversations: { user_id: @user.id })
        .where(role: "user")
        .where("messages.created_at >= ?", Time.current.beginning_of_day)
        .count
    end

    def daily_limit
      ENV.fetch("CHAT_DAILY_LIMIT", DEFAULT_DAILY_LIMIT).to_i
    end

    class RateLimitExceeded < StandardError; end
  end
end

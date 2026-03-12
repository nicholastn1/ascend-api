class Rack::Attack
  # Disable rate limiting in development
  if Rails.env.development?
    self.enabled = false
  end

  # Safelist health check endpoints from rate limiting
  safelist("health-checks") do |req|
    req.path == "/up" || req.path == "/api/v1/health"
  end

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login attempts by IP (5 attempts per 20 seconds)
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  # Throttle login attempts by email (5 attempts per minute)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      req.params.dig("email")&.to_s&.downcase&.strip
    end
  end

  # Throttle 2FA validation attempts (5 per minute per IP)
  throttle("2fa/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/auth/two-factor/validate" && req.post?
  end

  # Throttle registration by IP (3 per hour)
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  # Throttle password reset by IP (5 per hour)
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/forgot-password" && req.post?
  end

  # Throttle email verification by IP (10 per hour)
  throttle("email_verification/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/verify-email" && req.post?
  end

  # Return JSON body for throttled responses
  self.throttled_responder = lambda do |req|
    now = req.env["rack.attack.match_data"][:epoch_time]
    retry_after = req.env["rack.attack.match_data"][:period] - (now % req.env["rack.attack.match_data"][:period])

    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { error: "Rate limit exceeded. Retry after #{retry_after} seconds." }.to_json ]
    ]
  end
end

class Rack::Attack
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

  # Throttle registration by IP (3 per hour)
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  # Throttle password reset by IP (5 per hour)
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/forgot-password" && req.post?
  end
end

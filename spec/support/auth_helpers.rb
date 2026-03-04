module AuthHelpers
  def sign_in(user)
    session = create(:session, user: user)
    { "Cookie" => "session_token=#{session.token}" }
  end

  def auth_headers(user)
    session = create(:session, user: user)
    { "Authorization" => "Bearer #{session.token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end

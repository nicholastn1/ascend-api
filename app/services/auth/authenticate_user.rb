module Auth
  class AuthenticateUser
    def initialize(email:, password:, ip_address: nil, user_agent: nil)
      @email = email
      @password = password
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      user = User.find_by(email: @email&.downcase&.strip)
      raise AuthError, "Invalid email or password" unless user&.authenticate(@password)

      if user.two_factor_enabled?
        { user: user, requires_2fa: true }
      else
        session = create_session(user)
        { user: user, session: session, requires_2fa: false }
      end
    end

    private

    def create_session(user)
      user.sessions.create!(
        ip_address: @ip_address,
        user_agent: @user_agent
      )
    end
  end

  class AuthError < StandardError; end
end

module Auth
  class RegisterUser
    def initialize(params)
      @params = params
    end

    def call
      User.transaction do
        user = User.create!(
          name: @params[:name],
          email: @params[:email],
          username: @params[:username],
          password: @params[:password]
        )
        session = create_session(user)
        { user: user, session: session }
      end
    end

    private

    def create_session(user)
      user.sessions.create!(
        ip_address: @params[:ip_address],
        user_agent: @params[:user_agent]
      )
    end
  end
end

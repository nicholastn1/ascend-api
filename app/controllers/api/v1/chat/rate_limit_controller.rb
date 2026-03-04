module Api
  module V1
    module Chat
      class RateLimitController < BaseController
        def show
          usage = ::Chat::RateLimitChecker.new(user: current_user).usage
          render json: usage
        end
      end
    end
  end
end

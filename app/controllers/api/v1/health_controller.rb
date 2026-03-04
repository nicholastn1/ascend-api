module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: {
          status: "ok",
          version: "1.0.0",
          timestamp: Time.current.iso8601
        }
      end
    end
  end
end

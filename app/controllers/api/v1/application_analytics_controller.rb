module Api
  module V1
    class ApplicationAnalyticsController < BaseController
      def overview
        render json: analytics.overview
      end

      def timeline
        render json: analytics.timeline(
          period: params[:period] || "month",
          months: (params[:months] || 6).to_i
        )
      end

      def funnel
        render json: analytics.funnel
      end

      def avg_time
        render json: analytics.avg_time_per_stage
      end

      private

      def analytics
        @analytics ||= Applications::AnalyticsService.new(user: current_user)
      end
    end
  end
end

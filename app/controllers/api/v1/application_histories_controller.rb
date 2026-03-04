module Api
  module V1
    class ApplicationHistoriesController < BaseController
      def index
        application = current_user.job_applications.find(params[:application_id])
        histories = application.histories.order(changed_at: :desc)

        render json: histories.map { |h|
          {
            id: h.id,
            from_status: h.from_status,
            to_status: h.to_status,
            changed_at: h.changed_at
          }
        }
      end
    end
  end
end

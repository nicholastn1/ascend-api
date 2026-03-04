module Api
  module V1
    class ResumeStatisticsController < BaseController
      def show
        resume = current_user.resumes.find(params[:resume_id])
        stats = resume.statistics

        render json: {
          views: stats&.views || 0,
          downloads: stats&.downloads || 0,
          last_viewed_at: stats&.last_viewed_at,
          last_downloaded_at: stats&.last_downloaded_at
        }
      end
    end
  end
end

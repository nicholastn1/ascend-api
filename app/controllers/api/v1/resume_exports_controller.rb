module Api
  module V1
    class ResumeExportsController < BaseController
      before_action :set_resume

      def pdf
        url = Printer::GeneratePdf.new(resume: @resume).call
        render json: { url: url }
      rescue RuntimeError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      def screenshot
        url = Printer::GenerateScreenshot.new(resume: @resume).call
        render json: { url: url }
      rescue RuntimeError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      private

      def set_resume
        @resume = current_user.resumes.find(params[:id])
      end
    end
  end
end

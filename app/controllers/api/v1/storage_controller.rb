module Api
  module V1
    class StorageController < BaseController
      def upload
        result = Storage::UploadFile.new(
          user: current_user,
          file: params[:file],
          type: params[:type] || "picture",
          resume_id: params[:resume_id]
        ).call

        render json: result, status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def destroy
        unless params[:path].present?
          render json: { error: "Path is required" }, status: :unprocessable_content
          return
        end

        Storage::DeleteFile.new(
          user: current_user,
          path: params[:path]
        ).call

        render json: { deleted: true }
      end
    end
  end
end

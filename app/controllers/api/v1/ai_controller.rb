module Api
  module V1
    class AiController < BaseController
      def test_connection
        result = Ai::TestConnection.new(
          model_id: params[:model_id]
        ).call

        render json: result
      end

      def parse_pdf
        result = Ai::ParseDocument.new(
          file: params[:file],
          type: "pdf",
          model_id: params[:model_id]
        ).call

        render json: { data: result }
      rescue ArgumentError, RuntimeError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def parse_docx
        result = Ai::ParseDocument.new(
          file: params[:file],
          type: "docx",
          model_id: params[:model_id]
        ).call

        render json: { data: result }
      rescue ArgumentError, RuntimeError => e
        render json: { error: e.message }, status: :unprocessable_content
      end
    end
  end
end

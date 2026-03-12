# frozen_string_literal: true

module Api
  module V1
    class ApplicationWorkflowsController < BaseController
      def show
        service = Applications::WorkflowService.new(user: current_user)
        render json: { statuses: service.statuses }
      end

      def update
        service = Applications::WorkflowService.new(user: current_user)
        service.update!(workflow_params[:statuses] || [])
        render json: { statuses: service.statuses }
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def workflow_params
        params.permit(statuses: [:slug, :label, :is_custom, :color, :position])
      end
    end
  end
end

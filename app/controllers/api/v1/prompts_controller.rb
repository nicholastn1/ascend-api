module Api
  module V1
    class PromptsController < BaseController
      before_action :require_admin!, only: :update

      def index
        prompts = AiPrompt.all.order(:slug)
        render json: prompts.map { |p| prompt_json(p) }
      end

      def show
        prompt = AiPrompt.find_by!(slug: params[:slug])
        render json: prompt_json(prompt)
      end

      def update
        prompt = AiPrompt.find_by!(slug: params[:slug])
        prompt.update!(prompt_params)
        render json: prompt_json(prompt)
      end

      private

      def prompt_params
        params.permit(:title, :description, :content)
      end

      def require_admin!
        admin_emails = ENV.fetch("ADMIN_EMAILS", "").split(",").map(&:strip)
        unless admin_emails.include?(current_user.email)
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def prompt_json(prompt)
        {
          id: prompt.id,
          slug: prompt.slug,
          title: prompt.title,
          description: prompt.description,
          content: prompt.content,
          created_at: prompt.created_at,
          updated_at: prompt.updated_at
        }
      end
    end
  end
end

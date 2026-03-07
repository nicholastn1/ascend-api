module Api
  module V1
    class AiConfigController < BaseController
      before_action :require_admin!

      def show
        config = AiConfig.instance
        render json: config_json(config)
      end

      def update
        config = AiConfig.instance
        config.update!(config_params)
        render json: config_json(config)
      end

      def test_connection
        config = AiConfig.instance
        api_key = params[:api_key].presence || config.effective_api_key

        unless api_key.present?
          render json: { error: "No API key configured" }, status: :unprocessable_entity
          return
        end

        model_id = params[:model].presence || config.model
        provider = params[:provider].presence || config.provider

        chat = build_chat(provider, model_id, api_key, params[:base_url].presence || config.base_url)
        chat.ask("Say 'ok' and nothing else.")

        render json: { status: "ok", model: model_id, provider: provider }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def config_params
        params.permit(:provider, :model, :base_url).tap do |p|
          p[:encrypted_api_key] = params[:api_key] if params.key?(:api_key)
        end
      end

      def config_json(config)
        {
          provider: config.provider,
          model: config.model,
          base_url: config.base_url,
          has_api_key: config.has_api_key?,
          configured: config.configured?
        }
      end

      def build_chat(provider, model_id, api_key, base_url)
        connection_config = {}

        case provider
        when "openai"
          connection_config[:openai_api_key] = api_key
          connection_config[:openai_api_base] = base_url if base_url.present?
        when "anthropic"
          connection_config[:anthropic_api_key] = api_key
        when "gemini"
          connection_config[:gemini_api_key] = api_key
        when "openrouter"
          connection_config[:openrouter_api_key] = api_key
        end

        RubyLLM.chat(model: model_id, **connection_config)
      end

      def require_admin!
        admin_emails = ENV.fetch("ADMIN_EMAILS", "").split(",").map(&:strip)
        unless admin_emails.include?(current_user.email)
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end
    end
  end
end

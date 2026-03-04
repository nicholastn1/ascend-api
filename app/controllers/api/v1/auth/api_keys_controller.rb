module Api
  module V1
    module Auth
      class ApiKeysController < BaseController
        def index
          keys = ::Auth::ManageApiKeys.new(current_user).list
          render json: keys.map { |k| api_key_json(k) }
        end

        def create
          result = ::Auth::ManageApiKeys.new(current_user).create(
            name: params[:name],
            expires_at: params[:expires_at],
            permissions: params[:permissions] || []
          )
          render json: api_key_json(result[:api_key]).merge(key: result[:raw_key]), status: :created
        end

        def update
          key = ::Auth::ManageApiKeys.new(current_user).update(params[:id], api_key_params)
          render json: api_key_json(key)
        end

        def destroy
          ::Auth::ManageApiKeys.new(current_user).destroy(params[:id])
          render json: { message: "API key revoked" }
        end

        private

        def api_key_params
          params.permit(:name, :enabled, :expires_at)
        end

        def api_key_json(key)
          {
            id: key.id,
            name: key.name,
            key_start: key.key_start,
            enabled: key.enabled,
            request_count: key.request_count,
            last_request_at: key.last_request_at,
            expires_at: key.expires_at,
            created_at: key.created_at
          }
        end
      end
    end
  end
end

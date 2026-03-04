module Auth
  class ManageApiKeys
    def initialize(user)
      @user = user
    end

    def create(name:, expires_at: nil, permissions: [])
      generated = ApiKey.generate_key

      api_key = @user.api_keys.create!(
        name: name,
        key_digest: generated[:digest],
        key_start: generated[:key_start],
        prefix: "ak",
        expires_at: expires_at,
        permissions: permissions.to_json
      )

      { api_key: api_key, raw_key: generated[:raw_key] }
    end

    def update(id, params)
      api_key = @user.api_keys.find(id)
      api_key.update!(params.slice(:name, :enabled, :expires_at))
      api_key
    end

    def destroy(id)
      @user.api_keys.find(id).destroy!
    end

    def list
      @user.api_keys.order(created_at: :desc)
    end
  end
end

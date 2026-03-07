require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "Ascend API",
        version: "v1",
        description: "Career management platform API — resumes, job tracking, AI chat, and more."
      },
      paths: {},
      servers: [
        {
          url: "{protocol}://{host}",
          variables: {
            protocol: { default: "http", enum: %w[http https] },
            host: { default: "localhost:3000" }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer
          },
          cookie_auth: {
            type: :apiKey,
            in: :cookie,
            name: :session_token
          },
          api_key_auth: {
            type: :apiKey,
            in: :header,
            name: "X-API-Key"
          }
        }
      }
    }
  }

  config.openapi_format = :yaml

  # Strict schema validation
  config.openapi_strict_schema_validation = true
end

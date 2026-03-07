WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("FRONTEND_URL", "http://localhost:3000") ]
  config.rp_name = "Ascend"
  config.rp_id = ENV.fetch("WEBAUTHN_RP_ID", "localhost")
end

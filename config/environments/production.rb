require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.assume_ssl = true

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false

  config.active_storage.service = ENV["S3_BUCKET"].present? ? :amazon : :local

  config.cache_store = :memory_store

  config.i18n.fallbacks = true

  # Allow Active Record Encryption keys to come from Railway env vars while
  # still supporting Rails credentials when they are present.
  config.active_record.encryption.primary_key =
    ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"] ||
    Rails.application.credentials.dig(:active_record_encryption, :primary_key)
  config.active_record.encryption.deterministic_key =
    ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"] ||
    Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
  config.active_record.encryption.key_derivation_salt =
    ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"] ||
    Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.hosts = nil
end

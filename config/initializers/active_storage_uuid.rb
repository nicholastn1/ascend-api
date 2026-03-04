Rails.application.config.to_prepare do
  ActiveStorage::Blob.include HasUuid
  ActiveStorage::Attachment.include HasUuid
  ActiveStorage::VariantRecord.include HasUuid
end

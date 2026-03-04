class KnowledgeIngestJob < ApplicationJob
  queue_as :default

  def perform(knowledge_document_id)
    document = KnowledgeDocument.find(knowledge_document_id)

    # Fetch content if it's a Google Sheet
    if document.source_type == "google_sheet" && document.source_url.present?
      content = Knowledge::GoogleSheetService.fetch(source_url: document.source_url)
      document.update!(content: content, last_synced_at: Time.current)
    end

    # Generate embeddings
    count = Knowledge::EmbeddingService.embed_document(document)

    Rails.logger.info("KnowledgeIngestJob: Embedded #{count} chunks for document #{document.id}")
  rescue => e
    Rails.logger.error("KnowledgeIngestJob failed for document #{knowledge_document_id}: #{e.message}")
    raise # Re-raise so Solid Queue can retry
  end
end

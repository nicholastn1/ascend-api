class EmbedResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    count = Knowledge::EmbeddingService.embed_document(resume)
    Rails.logger.info("EmbedResumeJob: Embedded #{count} chunks for resume #{resume.id}")
  rescue ActiveRecord::RecordNotFound
    # Resume was deleted before job ran, ignore
  rescue => e
    Rails.logger.error("EmbedResumeJob failed for resume #{resume_id}: #{e.message}")
    raise
  end
end

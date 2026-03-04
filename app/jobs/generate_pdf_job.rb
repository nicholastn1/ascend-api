class GeneratePdfJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    Printer::GeneratePdf.new(resume: resume).call
  end
end

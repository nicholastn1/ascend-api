class GenerateScreenshotJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    Printer::GenerateScreenshot.new(resume: resume).call
  end
end

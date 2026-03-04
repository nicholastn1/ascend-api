require "rails_helper"

RSpec.describe EmbedResumeJob, type: :job do
  let(:user) { create(:user) }
  let(:resume) { create(:resume, user: user) }

  describe "#perform" do
    it "embeds the resume" do
      allow(Knowledge::EmbeddingService).to receive(:embed_document).and_return(1)

      described_class.perform_now(resume.id)

      expect(Knowledge::EmbeddingService).to have_received(:embed_document).with(resume)
    end

    it "silently handles deleted resumes" do
      expect {
        described_class.perform_now("nonexistent-id")
      }.not_to raise_error
    end
  end
end

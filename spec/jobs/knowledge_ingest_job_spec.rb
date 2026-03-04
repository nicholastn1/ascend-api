require "rails_helper"

RSpec.describe KnowledgeIngestJob, type: :job do
  let(:user) { create(:user) }

  describe "#perform" do
    context "with a text document" do
      let(:document) { create(:knowledge_document, user: user, content: "Some knowledge content.") }

      it "generates embeddings without fetching" do
        allow(Knowledge::EmbeddingService).to receive(:embed_document).and_return(1)

        described_class.perform_now(document.id)

        expect(Knowledge::EmbeddingService).to have_received(:embed_document).with(document)
      end
    end

    context "with a google_sheet document" do
      let(:document) { create(:knowledge_document, :google_sheet, user: user, content: nil) }

      it "fetches content from Google Sheets before embedding" do
        allow(Knowledge::GoogleSheetService).to receive(:fetch).and_return("Fetched sheet content")
        allow(Knowledge::EmbeddingService).to receive(:embed_document).and_return(1)

        described_class.perform_now(document.id)

        expect(Knowledge::GoogleSheetService).to have_received(:fetch).with(source_url: document.source_url)
        document.reload
        expect(document.content).to eq("Fetched sheet content")
        expect(document.last_synced_at).to be_present
      end
    end
  end
end

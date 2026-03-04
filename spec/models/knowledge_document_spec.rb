require "rails_helper"

RSpec.describe KnowledgeDocument, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_inclusion_of(:source_type).in_array(%w[google_sheet file text]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:embedding_chunks).dependent(:destroy) }
  end

  describe "google_sheet source_url validation" do
    it "requires source_url for google_sheet type" do
      doc = build(:knowledge_document, :google_sheet, source_url: nil)
      expect(doc).not_to be_valid
      expect(doc.errors[:source_url]).to include("can't be blank")
    end

    it "does not require source_url for text type" do
      doc = build(:knowledge_document, source_type: "text", source_url: nil)
      expect(doc).to be_valid
    end
  end
end

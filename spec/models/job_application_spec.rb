require "rails_helper"

RSpec.describe JobApplication, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_inclusion_of(:current_status).in_array(JobApplication::STATUSES) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:contacts).dependent(:destroy) }
    it { is_expected.to have_many(:histories).dependent(:destroy) }
  end

  describe "default status" do
    it "defaults to applied" do
      app = create(:job_application)
      expect(app.current_status).to eq("applied")
    end
  end
end

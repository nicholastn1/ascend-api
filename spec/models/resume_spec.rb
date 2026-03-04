require "rails_helper"

RSpec.describe Resume, type: :model do
  describe "validations" do
    subject { build(:resume) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:data) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:statistics) }
  end

  it "auto-creates statistics on create" do
    resume = create(:resume)
    expect(resume.statistics).to be_present
    expect(resume.statistics.views).to eq(0)
  end

  it "enforces unique slug per user" do
    user = create(:user)
    create(:resume, user: user, slug: "my-resume")
    expect { create(:resume, user: user, slug: "my-resume") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { create(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:resumes).dependent(:destroy) }
    it { is_expected.to have_many(:job_applications).dependent(:destroy) }
    it { is_expected.to have_many(:api_keys).dependent(:destroy) }
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
  end

  describe "UUID generation" do
    it "generates a UUID on create" do
      user = create(:user)
      expect(user.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end
  end

  describe "email normalization" do
    it "downcases email" do
      user = create(:user, email: "Test@Example.COM")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "password authentication" do
    it "authenticates with correct password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "rejects incorrect password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("wrong")).to be_falsey
    end
  end
end

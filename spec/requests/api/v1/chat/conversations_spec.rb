require "rails_helper"

RSpec.describe "Api::V1::Chat::Conversations", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/chat/conversations" do
    it "lists user's conversations" do
      create_list(:conversation, 3, user: user)
      create(:conversation) # another user's

      get "/api/v1/chat/conversations", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/chat/conversations"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/chat/conversations" do
    it "creates a conversation" do
      post "/api/v1/chat/conversations",
        params: { title: "My Chat", agent_type: "general" },
        headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["title"]).to eq("My Chat")
      expect(body["agent_type"]).to eq("general")
      expect(body["model_id"]).to be_present
    end

    it "creates a recruiter-reply conversation" do
      post "/api/v1/chat/conversations",
        params: { title: "Recruiter Reply", agent_type: "recruiter-reply" },
        headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["agent_type"]).to eq("recruiter-reply")
    end
  end

  describe "GET /api/v1/chat/conversations/:id" do
    it "returns conversation with messages" do
      conversation = create(:conversation, user: user)
      create(:message, conversation: conversation, role: "user", content: "Hello")
      create(:message, conversation: conversation, role: "assistant", content: "Hi there!")

      get "/api/v1/chat/conversations/#{conversation.id}", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["messages"].size).to eq(2)
      expect(body["messages"].first["role"]).to eq("user")
    end

    it "returns 404 for another user's conversation" do
      other = create(:conversation)
      get "/api/v1/chat/conversations/#{other.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/chat/conversations/:id" do
    it "updates conversation title" do
      conversation = create(:conversation, user: user, title: "Old Title")

      put "/api/v1/chat/conversations/#{conversation.id}",
        params: { title: "New Title" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("New Title")
    end
  end

  describe "DELETE /api/v1/chat/conversations/:id" do
    it "deletes conversation and messages" do
      conversation = create(:conversation, user: user)
      create(:message, conversation: conversation)

      expect {
        delete "/api/v1/chat/conversations/#{conversation.id}", headers: headers
      }.to change(Conversation, :count).by(-1)
        .and change(Message, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end

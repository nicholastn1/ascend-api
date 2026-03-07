require "swagger_helper"

RSpec.describe "Chat API", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ── Conversations ──────────────────────────────────────────────────────────

  path "/api/v1/chat/conversations" do
    get "List conversations" do
      tags "Chat"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "conversations listed" do
        before { create_list(:conversation, 2, user: user) }
        run_test!
      end
    end

    post "Create a conversation" do
      tags "Chat"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          agent_type: { type: :string },
          model_id: { type: :string }
        }
      }

      response "201", "conversation created" do
        let(:body) { { title: "My Chat", agent_type: "general" } }
        run_test!
      end
    end
  end

  path "/api/v1/chat/conversations/{id}" do
    parameter name: :id, in: :path, type: :string, description: "Conversation ID"

    let(:conversation) { create(:conversation, user: user) }
    let(:id) { conversation.id }

    get "Show a conversation" do
      tags "Chat"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "conversation found" do
        before do
          create(:message, conversation: conversation, role: "user", content: "Hello")
          create(:message, conversation: conversation, role: "assistant", content: "Hi there!")
        end

        run_test!
      end
    end

    put "Update a conversation" do
      tags "Chat"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string }
        }
      }

      response "200", "conversation updated" do
        let(:body) { { title: "Updated Title" } }
        run_test!
      end
    end

    delete "Delete a conversation" do
      tags "Chat"
      security [ { bearer_auth: [] } ]

      response "204", "conversation deleted" do
        run_test!
      end
    end
  end

  # ── Messages ───────────────────────────────────────────────────────────────

  path "/api/v1/chat/conversations/{conversation_id}/messages" do
    parameter name: :conversation_id, in: :path, type: :string, description: "Conversation ID"

    post "Send a message" do
      tags "Chat"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string },
          stream: { type: :string, enum: %w[true false] }
        },
        required: %w[content]
      }

      response "200", "message sent (sync mode)" do
        let(:conversation) { create(:conversation, user: user) }
        let(:conversation_id) { conversation.id }
        let(:body) { { content: "Hello!", stream: "false" } }

        before { skip "Requires AI provider" }
        run_test!
      end
    end
  end

  # ── Rate Limit ─────────────────────────────────────────────────────────────

  path "/api/v1/chat/rate-limit" do
    get "Check chat rate limit" do
      tags "Chat"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "rate limit info returned" do
        run_test!
      end
    end
  end
end

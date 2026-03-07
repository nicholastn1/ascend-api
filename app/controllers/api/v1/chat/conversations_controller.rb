module Api
  module V1
    module Chat
      class ConversationsController < BaseController
        before_action :set_conversation, only: %i[show update destroy]

        def index
          conversations = current_user.conversations.ordered
          render json: conversations.map { |c| conversation_json(c) }
        end

        def create
          model_id = params[:model_id] || default_model
          conversation = current_user.conversations.create!(
            title: params[:title] || "New Conversation",
            agent_type: params[:agent_type] || "general",
            model_id: model_id
          )

          render json: conversation_json(conversation), status: :created
        end

        def show
          render json: conversation_json(@conversation, include_messages: true)
        end

        def update
          @conversation.update!(params.permit(:title))
          render json: conversation_json(@conversation)
        end

        def destroy
          @conversation.destroy!
          head :no_content
        end

        private

        def set_conversation
          @conversation = current_user.conversations.find(params[:id])
        end

        def default_model
          AiConfig.instance.model
        end

        def conversation_json(conversation, include_messages: false)
          json = {
            id: conversation.id,
            title: conversation.title,
            agent_type: conversation.agent_type,
            model_id: conversation.model_id,
            created_at: conversation.created_at,
            updated_at: conversation.updated_at
          }

          if include_messages
            json[:messages] = conversation.messages.ordered.map { |m| message_json(m) }
          end

          json
        end

        def message_json(message)
          {
            id: message.id,
            role: message.role,
            content: message.content,
            input_tokens: message.input_tokens,
            output_tokens: message.output_tokens,
            created_at: message.created_at
          }
        end
      end
    end
  end
end

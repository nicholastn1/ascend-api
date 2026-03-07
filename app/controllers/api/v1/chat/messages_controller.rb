module Api
  module V1
    module Chat
      class MessagesController < BaseController
        include ActionController::Live

        before_action :set_conversation

        def create
          if params[:stream] == "true"
            stream_response
          else
            sync_response
          end
        end

        private

        def set_conversation
          @conversation = current_user.conversations.find(params[:conversation_id])
        end

        def sync_response
          response_msg = ::Chat::SendMessage.new(
            conversation: @conversation,
            content: params[:content]
          ).call

          render json: message_json(response_msg)
        rescue ::Chat::RateLimitChecker::RateLimitExceeded => e
          render json: { error: e.message }, status: :too_many_requests
        end

        def stream_response
          response.headers["Content-Type"] = "text/event-stream"
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"
          response.headers["X-Accel-Buffering"] = "no"

          response_msg = ::Chat::SendMessage.new(
            conversation: @conversation,
            content: params[:content]
          ) { |chunk|
            sse_write(chunk)
          }.call

          # Send final message with full data
          sse_write_event("done", message_json(response_msg))
        rescue ::Chat::RateLimitChecker::RateLimitExceeded => e
          sse_write_event("error", { error: e.message })
        rescue => e
          Rails.logger.error("Chat streaming error: #{e.class}: #{e.message}")
          sse_write_event("error", { error: "An error occurred processing your message" })
        ensure
          response.stream.close
        end

        def sse_write(chunk)
          data = { content: chunk.content }
          response.stream.write("data: #{data.to_json}\n\n")
        end

        def sse_write_event(event, data)
          response.stream.write("event: #{event}\ndata: #{data.to_json}\n\n")
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

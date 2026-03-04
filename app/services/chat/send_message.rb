module Chat
  class SendMessage
    def initialize(conversation:, content:, &on_chunk)
      @conversation = conversation
      @content = content
      @on_chunk = on_chunk
    end

    def call
      RateLimitChecker.new(user: @conversation.user).check!

      # Save user message
      @conversation.messages.create!(role: "user", content: @content)

      # Build RubyLLM chat with history
      chat = RubyLLM.chat(model: @conversation.model_id)

      # Set system prompt with RAG context
      system_prompt = load_system_prompt
      chat.with_instructions(system_prompt) if system_prompt.present?

      # Add tools
      chat.with_tool(PatchResumeTool) if @conversation.agent_type == "general"

      # Load conversation history
      @conversation.messages.ordered.each do |msg|
        next if msg.role == "system" # System prompt handled separately

        chat.add_message(role: msg.role.to_sym, content: msg.content)
      end

      # Get response
      assistant_msg = @conversation.messages.create!(role: "assistant", content: "")
      full_content = ""

      if @on_chunk
        chat.complete do |chunk|
          if chunk.content
            full_content += chunk.content
            @on_chunk.call(chunk)
          end
        end
      else
        response = chat.complete
        full_content = response.content
      end

      # Update assistant message with final content
      assistant_msg.update!(
        content: full_content,
        input_tokens: chat.messages.last&.input_tokens,
        output_tokens: chat.messages.last&.output_tokens
      )

      # Touch conversation to update ordering
      @conversation.touch

      assistant_msg
    rescue => e
      # Clean up empty assistant message on error
      @conversation.messages.where(role: "assistant", content: "").destroy_all
      raise
    end

    private

    def load_system_prompt
      slug = case @conversation.agent_type
      when "general" then "chat-system"
      when "recruiter-reply" then "recruiter-reply-system"
      end

      return unless slug

      prompt = AiPrompt.find_by(slug: slug)
      return unless prompt

      content = prompt.content

      # Inject resume data if available
      if content.include?("{{RESUME_DATA}}")
        resume = @conversation.user.resumes.ordered.first
        resume_json = resume ? resume.data.to_json : "{}"
        content = content.gsub("{{RESUME_DATA}}", resume_json)
      end

      # Inject RAG context from knowledge base
      rag_context = fetch_rag_context
      if rag_context.present?
        content += "\n\n## Relevant Knowledge Base Context\n\n#{rag_context}"
      end

      content
    end

    def fetch_rag_context
      return nil unless @content.present?
      return nil unless has_knowledge_base?

      Knowledge::SemanticSearch.build_context(
        query: @content,
        user: @conversation.user,
        limit: 3
      )
    rescue => e
      Rails.logger.warn("RAG context fetch failed: #{e.message}")
      nil
    end

    def has_knowledge_base?
      @conversation.user.knowledge_documents.exists? ||
        @conversation.user.resumes.joins(:embedding_chunks).exists?
    end
  end
end

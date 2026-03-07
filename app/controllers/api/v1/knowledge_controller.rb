module Api
  module V1
    class KnowledgeController < BaseController
      before_action :set_document, only: %i[update destroy sync]

      # GET /api/v1/knowledge
      def index
        documents = current_user.knowledge_documents.order(updated_at: :desc)
        render json: documents.map { |d| document_json(d) }
      end

      # POST /api/v1/knowledge
      def create
        document = current_user.knowledge_documents.new(document_params)

        # For text source, content is provided directly
        if document.source_type == "text"
          document.content = params[:content]
        end

        if document.save
          # Async ingest: fetch content (for Google Sheets) and generate embeddings
          KnowledgeIngestJob.perform_later(document.id)
          render json: document_json(document), status: :created
        else
          render json: { errors: document.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PUT /api/v1/knowledge/:id
      def update
        if @document.update(document_params.merge(content_params))
          # Re-embed if content changed
          if @document.saved_change_to_content?
            KnowledgeIngestJob.perform_later(@document.id)
          end
          render json: document_json(@document)
        else
          render json: { errors: @document.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/knowledge/:id
      def destroy
        # Remove embeddings first
        Knowledge::EmbeddingService.remove_embeddings(@document)
        @document.destroy!
        head :no_content
      end

      # POST /api/v1/knowledge/:id/sync
      def sync
        unless @document.source_type == "google_sheet"
          render json: { error: "Only Google Sheet documents can be synced" }, status: :unprocessable_content
          return
        end

        KnowledgeIngestJob.perform_later(@document.id)
        render json: { message: "Sync started", document: document_json(@document) }
      end

      # POST /api/v1/knowledge/search
      def search
        query = params[:query]
        if query.blank?
          render json: { error: "Query is required" }, status: :unprocessable_content
          return
        end

        limit = (params[:limit] || 5).to_i.clamp(1, 20)
        results = Knowledge::SemanticSearch.search(query: query, user: current_user, limit: limit)
        render json: { results: results }
      end

      private

      def set_document
        @document = current_user.knowledge_documents.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Document not found" }, status: :not_found
      end

      def document_params
        params.permit(:title, :source_type, :source_url)
      end

      def content_params
        params.permit(:content)
      end

      def document_json(doc)
        {
          id: doc.id,
          title: doc.title,
          source_type: doc.source_type,
          source_url: doc.source_url,
          content_preview: doc.content&.truncate(200),
          chunks_count: doc.embedding_chunks.count,
          last_synced_at: doc.last_synced_at,
          metadata: doc.metadata,
          created_at: doc.created_at,
          updated_at: doc.updated_at
        }
      end
    end
  end
end

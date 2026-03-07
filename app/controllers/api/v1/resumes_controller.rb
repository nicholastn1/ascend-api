module Api
  module V1
    class ResumesController < BaseController
      before_action :set_resume, only: %i[show update destroy patch_data duplicate lock set_password remove_password]

      def index
        resumes = current_user.resumes.ordered
        if params[:tag].present?
          sanitized_tag = params[:tag].gsub(/[%_]/, "")
          resumes = resumes.where("json_extract(tags, '$') LIKE ?", "%#{sanitized_tag}%")
        end

        render json: resumes.map { |r| resume_summary_json(r) }
      end

      def show
        render json: resume_json(@resume)
      end

      def create
        create_params = resume_params.to_h.merge(data: params[:data]&.to_unsafe_h).compact
        resume = ::Resumes::CreateResume.new(current_user, create_params).call
        render json: resume_json(resume), status: :created
      end

      def update
        raise ::Resumes::ResumeLockedError, "Resume is locked" if @resume.locked?

        @resume.update!(resume_params.except(:data).merge(
          data: params[:data].present? ? params[:data].to_unsafe_h : @resume.data
        ))
        render json: resume_json(@resume)
      rescue ::Resumes::ResumeLockedError => e
        render json: { error: e.message }, status: :forbidden
      end

      def destroy
        @resume.destroy!
        render json: { message: "Resume deleted" }
      end

      def patch_data
        operations = params[:operations]
        resume = ::Resumes::PatchResume.new(@resume, operations).call
        render json: resume_json(resume)
      rescue ::Resumes::ResumeLockedError => e
        render json: { error: e.message }, status: :forbidden
      end

      def duplicate
        new_resume = ::Resumes::DuplicateResume.new(@resume).call
        render json: resume_json(new_resume), status: :created
      end

      def lock
        @resume.update!(is_locked: !@resume.is_locked)
        render json: resume_json(@resume)
      end

      def set_password
        unless params[:password].present?
          render json: { error: "Password is required" }, status: :unprocessable_content
          return
        end

        @resume.update!(password: params[:password])
        render json: { message: "Password set" }
      end

      def remove_password
        @resume.update!(password_digest: nil)
        render json: { message: "Password removed" }
      end

      def tags
        tags = current_user.resumes.pluck(:tags).flatten.uniq.compact
        render json: tags
      end

      def import
        resume = ::Resumes::CreateResume.new(current_user, {
          name: params[:name] || "Imported Resume",
          data: params[:data]
        }).call
        render json: resume_json(resume), status: :created
      end

      private

      def set_resume
        @resume = current_user.resumes.find(params[:id])
      end

      def resume_params
        params.permit(:name, :slug, :is_public, tags: [])
      end

      def resume_json(resume)
        {
          id: resume.id,
          name: resume.name,
          slug: resume.slug,
          tags: resume.tags,
          is_public: resume.is_public,
          is_locked: resume.is_locked,
          has_password: resume.password_protected?,
          data: resume.data,
          statistics: resume.statistics&.then { |s| { views: s.views, downloads: s.downloads } },
          created_at: resume.created_at,
          updated_at: resume.updated_at
        }
      end

      def resume_summary_json(resume)
        resume_json(resume).except(:data)
      end
    end
  end
end

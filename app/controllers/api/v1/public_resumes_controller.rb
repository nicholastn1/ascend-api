module Api
  module V1
    class PublicResumesController < BaseController
      skip_before_action :authenticate_user!

      def show
        user = User.find_by!(username: params[:username])
        resume = user.resumes.public_resumes.find_by!(slug: params[:slug])

        resume.statistics&.record_view!

        if resume.password_protected?
          render json: { requires_password: true, id: resume.id }
        else
          render json: public_resume_json(resume)
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Resume not found" }, status: :not_found
      end

      def verify
        user = User.find_by!(username: params[:username])
        resume = user.resumes.public_resumes.find_by!(slug: params[:slug])

        if resume.authenticate_password(params[:password])
          render json: public_resume_json(resume)
        else
          render json: { error: "Invalid password" }, status: :unauthorized
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Resume not found" }, status: :not_found
      end

      private

      def public_resume_json(resume)
        {
          id: resume.id,
          name: resume.name,
          slug: resume.slug,
          data: resume.data,
          user: {
            name: resume.user.name,
            username: resume.user.username,
            image: resume.user.image
          }
        }
      end
    end
  end
end

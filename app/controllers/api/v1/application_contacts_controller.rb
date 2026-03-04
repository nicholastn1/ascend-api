module Api
  module V1
    class ApplicationContactsController < BaseController
      before_action :set_application
      before_action :set_contact, only: %i[update destroy]

      def index
        render json: @application.contacts.map { |c| contact_json(c) }
      end

      def create
        contact = @application.contacts.create!(contact_params)
        render json: contact_json(contact), status: :created
      end

      def update
        @contact.update!(contact_params)
        render json: contact_json(@contact)
      end

      def destroy
        @contact.destroy!
        head :no_content
      end

      private

      def set_application
        @application = current_user.job_applications.find(params[:application_id])
      end

      def set_contact
        @contact = @application.contacts.find(params[:id])
      end

      def contact_params
        params.permit(:name, :role, :email, :phone, :linkedin_url)
      end

      def contact_json(contact)
        {
          id: contact.id,
          name: contact.name,
          role: contact.role,
          email: contact.email,
          phone: contact.phone,
          linkedin_url: contact.linkedin_url,
          created_at: contact.created_at,
          updated_at: contact.updated_at
        }
      end
    end
  end
end

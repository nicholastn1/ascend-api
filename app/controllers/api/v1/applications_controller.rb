module Api
  module V1
    class ApplicationsController < BaseController
      before_action :set_application, only: %i[show update destroy move]

      def index
        apps = current_user.job_applications.ordered
        apps = apply_filters(apps)

        render json: apps.map { |a| application_json(a) }
      end

      def kanban
        apps = current_user.job_applications

        grouped = JobApplication::STATUSES.index_with do |status|
          apps.by_status(status).ordered.map { |a| application_json(a) }
        end

        render json: grouped
      end

      def show
        render json: application_json(@application, include_relations: true)
      end

      def create
        app = current_user.job_applications.create!(application_params)

        # Record initial history
        app.histories.create!(
          to_status: app.current_status,
          changed_at: Time.current
        )

        render json: application_json(app), status: :created
      end

      def update
        @application.update!(application_params)
        render json: application_json(@application)
      end

      def move
        Applications::MoveApplication.new(
          application: @application,
          new_status: params.require(:status)
        ).call

        render json: application_json(@application.reload, include_relations: true)
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def destroy
        @application.destroy!
        head :no_content
      end

      private

      def set_application
        @application = current_user.job_applications.find(params[:id])
      end

      def application_params
        params.permit(
          :company_name, :job_title, :job_url, :current_status,
          :salary_amount, :salary_currency, :salary_period,
          :notes, :application_date
        )
      end

      def apply_filters(scope)
        scope = scope.by_status(params[:status]) if params[:status].present?
        scope = scope.where("company_name LIKE ?", "%#{params[:company]}%") if params[:company].present?

        if params[:date_from].present?
          scope = scope.where("application_date >= ?", params[:date_from])
        end
        if params[:date_to].present?
          scope = scope.where("application_date <= ?", params[:date_to])
        end

        if params[:salary_min].present?
          scope = scope.where("salary_amount >= ?", params[:salary_min])
        end
        if params[:salary_max].present?
          scope = scope.where("salary_amount <= ?", params[:salary_max])
        end

        scope
      end

      def application_json(app, include_relations: false)
        json = {
          id: app.id,
          company_name: app.company_name,
          job_title: app.job_title,
          job_url: app.job_url,
          current_status: app.current_status,
          salary_amount: app.salary_amount,
          salary_currency: app.salary_currency,
          salary_period: app.salary_period,
          notes: app.notes,
          application_date: app.application_date,
          created_at: app.created_at,
          updated_at: app.updated_at
        }

        if include_relations
          json[:contacts] = app.contacts.map { |c| contact_json(c) }
          json[:history] = app.histories.order(changed_at: :desc).map { |h| history_json(h) }
        end

        json
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

      def history_json(history)
        {
          id: history.id,
          from_status: history.from_status,
          to_status: history.to_status,
          changed_at: history.changed_at
        }
      end
    end
  end
end

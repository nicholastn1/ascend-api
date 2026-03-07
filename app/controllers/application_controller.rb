class ApplicationController < ActionController::API
  include ActionController::Cookies

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_content
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_content(exception)
    render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_content
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end

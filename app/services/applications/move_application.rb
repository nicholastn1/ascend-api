module Applications
  class MoveApplication
    def initialize(application:, new_status:)
      @application = application
      @new_status = new_status
    end

    def call
      validate_status!

      @application.transaction do
        old_status = @application.current_status

        @application.update!(current_status: @new_status)

        @application.histories.create!(
          from_status: old_status,
          to_status: @new_status,
          changed_at: Time.current
        )
      end

      @application
    end

    private

    def validate_status!
      user = @application.user
      valid = JobApplication::STATUSES.include?(@new_status) ||
        user&.custom_statuses&.exists?(slug: @new_status)
      raise ArgumentError, "Invalid status: #{@new_status}" unless valid
    end
  end
end

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
      unless JobApplication::STATUSES.include?(@new_status)
        raise ArgumentError, "Invalid status: #{@new_status}"
      end
    end
  end
end

# frozen_string_literal: true

module Applications
  class MigrateStatus
    def initialize(user:, from_status:, to_status:)
      @user = user
      @from_status = from_status
      @to_status = to_status
    end

    def call
      validate!

      apps = @user.job_applications.where(current_status: @from_status).to_a
      count = apps.size

      apps.each do |app|
        Applications::MoveApplication.new(
          application: app,
          new_status: @to_status
        ).call
      end

      { migrated_count: count }
    end

    private

    def validate!
      workflow = WorkflowService.new(user: @user)
      raise ArgumentError, "Invalid from_status: #{@from_status}" unless workflow.valid_status?(@from_status)
      raise ArgumentError, "Invalid to_status: #{@to_status}" unless workflow.valid_status?(@to_status)
      raise ArgumentError, "from_status and to_status must be different" if @from_status == @to_status
    end
  end
end

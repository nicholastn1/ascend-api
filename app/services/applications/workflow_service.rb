# frozen_string_literal: true

module Applications
  class WorkflowService
    SYSTEM_STATUSES = JobApplication::STATUSES.dup.freeze
    SYSTEM_LABELS = {
      "applied" => "Applied",
      "screening" => "Screening",
      "interviewing" => "Interviewing",
      "offer" => "Offer",
      "accepted" => "Accepted",
      "rejected" => "Rejected",
      "withdrawn" => "Withdrawn"
    }.freeze
    DEFAULT_COLORS = {
      "applied" => "#3b82f6",
      "screening" => "#8b5cf6",
      "interviewing" => "#06b6d4",
      "offer" => "#22c55e",
      "accepted" => "#10b981",
      "rejected" => "#ef4444",
      "withdrawn" => "#6b7280"
    }.freeze

    def initialize(user:)
      @user = user
    end

    def statuses
      slugs = ordered_slugs
      result = []

      slugs.each_with_index do |slug, position|
        if SYSTEM_STATUSES.include?(slug)
          result << {
            slug: slug,
            label: SYSTEM_LABELS[slug],
            is_custom: false,
            color: DEFAULT_COLORS[slug],
            position: position
          }
        else
          custom = @user.custom_statuses.find_by(slug: slug)
          next unless custom

          result << {
            slug: custom.slug,
            label: custom.label,
            is_custom: true,
            color: custom.color.presence || "#8b5cf6",
            position: position
          }
        end
      end

      result
    end

    def valid_status?(slug)
      return true if SYSTEM_STATUSES.include?(slug)
      @user.custom_statuses.exists?(slug: slug)
    end

    def ordered_slugs
      workflow = @user.application_workflow
      slugs = workflow&.status_slugs&.presence

      if slugs.present?
        # Filter to only include slugs that still exist (system or custom)
        valid = SYSTEM_STATUSES + @user.custom_statuses.pluck(:slug)
        slugs.select { |s| valid.include?(s) }
      else
        SYSTEM_STATUSES
      end
    end

    def update!(statuses_params)
      slugs = statuses_params.map { |s| s[:slug].to_s }.reject(&:blank?)
      raise ArgumentError, "Workflow must have at least one column." if slugs.empty?

      custom_in_list = statuses_params.select { |s| s[:is_custom] }

      # Validate: cannot remove a status that has applications
      current_slugs = ordered_slugs
      slugs_to_remove = current_slugs - slugs
      slugs_to_remove.each do |slug|
        count = @user.job_applications.where(current_status: slug).count
        raise ArgumentError, "Cannot remove status '#{slug}': #{count} application(s) use it. Migrate them first." if count.positive?
      end

      @user.transaction do
        # Create/update custom statuses in the list
        custom_in_list.each_with_index do |params, idx|
          slug = params[:slug].to_s
          next if slug.blank?
          next if SYSTEM_STATUSES.include?(slug)

          custom = @user.custom_statuses.find_or_initialize_by(slug: slug)
          custom.label = params[:label].presence || slug.titleize
          custom.color = params[:color].presence
          custom.position = params[:position] || idx
          custom.save!
        end

        # Remove custom statuses no longer in the list (validation above ensures no apps use them)
        @user.custom_statuses.where.not(slug: slugs).destroy_all

        # Update workflow order
        workflow = @user.application_workflow || @user.build_application_workflow
        workflow.status_slugs = slugs
        workflow.save!
      end
    end
  end
end

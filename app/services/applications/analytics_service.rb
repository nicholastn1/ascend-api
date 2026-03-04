module Applications
  class AnalyticsService
    def initialize(user:)
      @user = user
      @applications = @user.job_applications
    end

    def overview
      counts = @applications.group(:current_status).count
      total = counts.values.sum

      {
        total: total,
        by_status: JobApplication::STATUSES.index_with { |s| counts[s] || 0 }
      }
    end

    def timeline(period: "month", months: 6)
      start_date = months.months.ago.beginning_of_month

      apps = @applications.where("created_at >= ?", start_date)

      grouped = case period
      when "week"
        apps.group_by { |a| a.created_at.beginning_of_week.to_date }
      else
        apps.group_by { |a| a.created_at.beginning_of_month.to_date }
      end

      grouped.transform_values(&:count).sort_by(&:first).map do |date, count|
        { date: date.iso8601, count: count }
      end
    end

    def funnel
      totals = @applications.group(:current_status).count
      total = @applications.count

      return [] if total == 0

      # Order statuses by typical progression
      progression = %w[applied screening interview offer negotiation accepted]

      cumulative = total
      progression.map do |status|
        count = totals[status] || 0
        rate = (cumulative.to_f / total * 100).round(1)
        result = { status: status, count: count, cumulative: cumulative, rate: rate }
        cumulative -= count
        result
      end
    end

    def avg_time_per_stage
      histories = JobApplicationHistory
        .joins("INNER JOIN job_applications ON job_applications.id = job_application_histories.application_id")
        .where(job_applications: { user_id: @user.id })
        .order(:application_id, :changed_at)

      stage_durations = Hash.new { |h, k| h[k] = [] }

      # Group histories by application and calculate time between transitions
      histories.group_by(&:application_id).each do |_app_id, app_histories|
        app_histories.each_cons(2) do |prev, curr|
          days = (curr.changed_at - prev.changed_at).to_f / 1.day
          stage_durations[prev.to_status] << days
        end
      end

      JobApplication::STATUSES.map do |status|
        durations = stage_durations[status]
        avg = durations.empty? ? 0 : (durations.sum / durations.size).round(1)
        { status: status, avg_days: avg, sample_size: durations.size }
      end
    end
  end
end

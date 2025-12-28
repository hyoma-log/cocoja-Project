class UpdateWeeklyRankingJob < ApplicationJob
  queue_as :default

  def perform
    @year, @week_number, @start_date, @end_date = previous_week_info

    clear_existing_rankings

    prefecture_points = Prefecture.weekly_points_for_all(@start_date, @end_date)

    Prefecture.all.index_by(&:id)

    create_rankings(prefecture_points)

    Rails.logger.info "Weekly ranking updated for Year: #{@year}, Week: #{@week_number}"
  end

  private

  def previous_week_info
    prev_week = Time.zone.now.beginning_of_week - 1.day
    year = prev_week.year
    week_number = prev_week.strftime('%U').to_i
    start_date = prev_week.beginning_of_week
    end_date = prev_week.end_of_week.end_of_day

    [year, week_number, start_date, end_date]
  end

  def clear_existing_rankings
    WeeklyRanking.where(year: @year, week: @week_number).destroy_all
  end

  def create_rankings(prefecture_points)
    ranked_prefectures = prefecture_points.sort_by { |_, points| -points }

    ActiveRecord::Base.transaction do
      ranked_prefectures.each_with_index do |(prefecture_id, points), index|
        next if points.zero?

        WeeklyRanking.create!(
          prefecture_id: prefecture_id,
          year: @year,
          week: @week_number,
          rank: index + 1,
          points: points
        )
      end
    end
  end
end

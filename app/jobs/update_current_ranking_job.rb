class UpdateCurrentRankingJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.zone.now
    year = now.year
    week_number = now.strftime('%U').to_i
    start_date = now.beginning_of_week
    end_date = now

    WeeklyRanking.where(year: year, week: week_number).destroy_all

    prefecture_points = Prefecture.weekly_points_for_all(start_date, end_date)

    prefectures = Prefecture.all.index_by(&:id)

    prefectures.each_key do |id|
      prefecture_points[id] ||= 0
    end

    ranked_prefectures = prefecture_points.sort_by { |_, points| -points }

    ActiveRecord::Base.transaction do
      ranked_prefectures.each_with_index do |(prefecture_id, points), index|
        WeeklyRanking.create!(
          prefecture_id: prefecture_id,
          year: year,
          week: week_number,
          rank: index + 1,
          points: points
        )
      end
    end

    Rails.cache.delete('current_rankings')
  end
end

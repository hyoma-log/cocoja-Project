class RankingsController < ApplicationController
  def index
    @current_rankings = Rails.cache.fetch('current_rankings', expires_in: 1.hour) do
      rankings = WeeklyRanking.current_week.includes(:prefecture).order(rank: :asc)

      if rankings.empty?
        calculate_current_rankings
      else
        rankings.map do |ranking|
          { prefecture: ranking.prefecture, rank: ranking.rank, points: ranking.points }
        end
      end
    end

    @previous_rankings = Rails.cache.fetch('previous_rankings', expires_in: 1.day) do
      WeeklyRanking.previous_week.includes(:prefecture).order(rank: :asc).map do |ranking|
        { prefecture: ranking.prefecture, rank: ranking.rank, points: ranking.points }
      end
    end
  end

  private

  def calculate_current_rankings
    start_date = Time.zone.now.beginning_of_week
    end_date = Time.zone.now

    prefecture_points = calculate_prefecture_points(start_date, end_date)

    sorted_prefectures = prefecture_points.values.sort_by { |p| -p[:points] }

    sorted_prefectures.map.with_index do |data, index|
      { prefecture: data[:prefecture], rank: index + 1, points: data[:points] }
    end
  end

  def calculate_prefecture_points(start_date, end_date)
    points_by_prefecture_id = Prefecture.weekly_points_for_all(start_date, end_date)

    prefectures_by_id = Prefecture.all.index_by(&:id)

    prefecture_points = {}

    prefectures_by_id.each do |id, prefecture|
      points = points_by_prefecture_id[id] || 0
      prefecture_points[id] = { prefecture: prefecture, points: points }
    end

    prefecture_points
  end
end

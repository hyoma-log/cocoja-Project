class WeeklyRanking < ApplicationRecord
  belongs_to :prefecture

  validates :year, presence: true
  validates :week, presence: true
  validates :rank, presence: true
  validates :points, presence: true

  scope :current_week, lambda {
    now = Time.zone.now
    year = now.year
    week = now.strftime('%U').to_i
    where(year: year, week: week)
  }

  scope :previous_week, lambda {
    prev_week = 1.week.ago
    year = prev_week.year
    week = prev_week.strftime('%U').to_i
    where(year: year, week: week)
  }

  def rank_change_from_previous
    prev_ranking = WeeklyRanking.previous_week.find_by(prefecture_id: prefecture_id)

    return nil unless prev_ranking

    prev_ranking.rank - rank
  end
end

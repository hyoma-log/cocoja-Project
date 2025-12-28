class Prefecture < ApplicationRecord
  has_many :posts, dependent: :nullify
  has_many :weekly_rankings, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }

  def weekly_points(start_date, end_date)
    Post.joins(:votes)
        .where(prefecture_id: id)
        .where('votes.created_at BETWEEN ? AND ?', start_date, end_date)
        .sum('votes.points')
  end

  def current_week_points
    start_date = Time.zone.now.beginning_of_week
    end_date = Time.zone.now
    weekly_points(start_date, end_date)
  end

  def self.weekly_points_for_all(start_date, end_date)
    Post.joins(:votes)
        .where('votes.created_at BETWEEN ? AND ?', start_date, end_date)
        .group(:prefecture_id)
        .sum('votes.points')
  end
end

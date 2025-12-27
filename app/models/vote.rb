class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :points, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: 5
  }

  validates :user_id, uniqueness: {
    scope: [:post_id, :voted_on],
    message: '同じ投稿には1日1回しかポイントを付けられません'
  }

  validate :daily_point_limit
  validate :cannot_vote_own_post

  # scope :today, lambda {
  #   where("DATE(created_at AT TIME ZONE 'UTC') = ?", Time.zone.today)
  # }
  scope :today, lambda {
    # Time.zone.todayの開始時刻から終了時刻までの範囲を指定
    where(created_at: Time.zone.now.all_day)
  }

  before_validation :set_voted_on

  private

  def daily_point_limit
    return unless user && points

    total_points_today = user.votes.today.sum(:points)
    total_after_vote = total_points_today + points.to_i

    return unless total_after_vote > 5

    errors.add(:points, "1日の投票ポイント上限（5ポイント）を超えています。残り#{5 - total_points_today}ポイントです。")
  end

  def cannot_vote_own_post
    return unless user && post
    return unless user_id == post.user_id

    errors.add(:post, '自分の投稿にはポイントを付けられません')
  end

  def set_voted_on
    self.voted_on = Time.zone.today
  end
end
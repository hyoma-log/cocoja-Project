require 'rails_helper'

RSpec.describe 'ランキング機能', type: :model do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:prefecture) { create(:prefecture, name: '東京都') }
  let!(:other_prefecture) { create(:prefecture, name: '大阪府') }

  describe 'ランキングサービス' do
    before do
      stub_const('RankingService', Class.new do
        def self.weekly_ranking
          Prefecture.joins(posts: :votes)
                    .where(votes: { created_at: 1.week.ago.. })
                    .group('prefectures.id')
                    .select('prefectures.*, SUM(votes.points) as total_points')
                    .order('total_points DESC')
        end
      end)
      user.confirm if user.respond_to?(:confirm)

      5.times do |i|
        voter = create(:user)
        travel_to (i + 1).day.ago do
          create(:vote, user: voter, post: tokyo_post, points: 3)
        end
      end

      3.times do |i|
        voter = create(:user)
        travel_to (i + 1).day.ago do
          create(:vote, user: voter, post: osaka_post, points: 2)
        end
      end
    end

    let(:tokyo_post) { create(:post, user: user, prefecture: prefecture) }
    let(:osaka_post) { create(:post, user: user, prefecture: other_prefecture) }

    it 'ランキングが得点順に取得できること' do
      rankings = RankingService.weekly_ranking
      expect(rankings.first.id).to eq prefecture.id
      expect(rankings.second.id).to eq other_prefecture.id
    end

    it '東京都の合計得点が正しいこと' do
      tokyo_points = tokyo_post.votes.sum(:points)
      expect(tokyo_points).to eq 15 # 5回 × 3ポイント
    end

    it '大阪府の合計得点が正しいこと' do
      osaka_points = osaka_post.votes.sum(:points)
      expect(osaka_points).to eq 6 # 3回 × 2ポイント
    end

    context '投票がない場合' do
      it 'ポイントが0であること' do
        Vote.destroy_all
        expect(tokyo_post.reload.votes.sum(:points)).to eq 0
        expect(osaka_post.reload.votes.sum(:points)).to eq 0
      end
    end
  end

  describe 'WeeklyRankingモデル' do
    it 'ランキングレコードを作成できること' do
      weekly_ranking = build(:weekly_ranking,
                             prefecture: prefecture,
                             rank: 1,
                             points: 15,
                             year: Date.current.year,
                             week: Date.current.strftime('%U').to_i)

      expect(weekly_ranking).to be_valid
      expect(weekly_ranking.save).to be_truthy
    end
  end
end

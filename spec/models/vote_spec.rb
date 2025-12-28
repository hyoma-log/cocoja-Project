require 'rails_helper'

RSpec.describe Vote, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post) }
  end

  describe 'validations' do
    subject(:vote) { build(:vote) }

    it 'validates numericality of points' do
      expect(vote).to validate_numericality_of(:points)
        .only_integer
        .is_greater_than(0)
        .is_less_than_or_equal_to(5)
    end

    describe 'daily_point_limit' do
      let(:user) { create(:user) }
      let(:post) { create(:post) }

      it 'allows voting within daily limit' do
        vote = build(:vote, user: user, post: post, points: 3)
        expect(vote).to be_valid
      end

      it 'prevents voting over daily limit' do
        create(:vote, user: user, points: 4)
        vote = build(:vote, user: user, post: post, points: 2)
        expect(vote).not_to be_valid
        expect(vote.errors[:points]).to include('1日の投票ポイント上限（5ポイント）を超えています。残り1ポイントです。')
      end
    end

    describe 'cannot_vote_own_post' do
      let(:user) { create(:user) }

      it 'prevents voting on own post' do
        post = create(:post, user: user)
        vote = build(:vote, user: user, post: post)
        expect(vote).not_to be_valid
        expect(vote.errors[:post]).to include('自分の投稿にはポイントを付けられません')
      end
    end

    describe 'uniqueness validation' do
      let(:user) { create(:user) }
      let(:post) { create(:post) }

      it 'prevents voting twice on same post' do
        create(:vote, user: user, post: post, points: 2)
        vote = build(:vote, user: user, post: post, points: 1)
        expect(vote).not_to be_valid
        expect(vote.errors[:user_id]).to include('同じ投稿には1日1回しかポイントを付けられません')
      end
    end
  end

  describe 'scopes' do
    describe '.today' do
      let(:user) { create(:user) }

      it 'returns only votes from today' do
        today_vote = create(:vote, created_at: Time.current)
        yesterday_vote = create(:vote, created_at: 1.day.ago)

        expect(described_class.today).to include(today_vote)
        expect(described_class.today).not_to include(yesterday_vote)
      end
    end
  end
end

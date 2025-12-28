require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject(:user) { create(:user) }

    it { is_expected.to validate_presence_of(:email) }

    context 'email uniqueness' do
      subject(:user) { create(:user) }

      it 'validates uniqueness of email' do
        dup_user = build(:user, email: user.email)
        expect(dup_user).not_to be_valid
        expect(dup_user.errors[:email]).to include('は既に使用されています')
      end

      it 'validates case insensitive uniqueness of email' do
        dup_user = build(:user, email: user.email.upcase)
        expect(dup_user).not_to be_valid
        expect(dup_user.errors[:email]).to include('は既に使用されています')
      end
    end

    context 'when on update' do
      subject(:user) { create(:user) }

      it { is_expected.to validate_presence_of(:username).on(:update) }
      it { is_expected.to validate_length_of(:username).is_at_least(1).is_at_most(20).on(:update) }
      it { is_expected.to validate_uniqueness_of(:username).on(:update) }

      it { is_expected.to validate_presence_of(:uid).on(:update) }
      it { is_expected.to validate_length_of(:uid).is_at_least(6).is_at_most(15).on(:update) }
      it { is_expected.to validate_uniqueness_of(:uid).on(:update) }

      it { is_expected.to validate_length_of(:bio).is_at_most(160) }
      it { is_expected.to allow_value('').for(:bio) }
      it { is_expected.to allow_value(nil).for(:bio) }

      it 'validates uid format' do
        user = create(:user)

        user.uid = 'abc123'
        expect(user).to be_valid

        user.uid = 'abc-123'
        expect(user).not_to be_valid
        expect(user.errors[:uid]).to include('は半角英数字のみ使用できます')
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
  end

  describe 'methods' do
    let(:user) { create(:user) }

    describe '#daily_votes_count' do
      it 'returns sum of today votes points' do
        travel_to(1.day.ago) do
          create(:vote, user: user, points: 1)
        end

        freeze_time do
          create(:vote, user: user, points: 2)
          create(:vote, user: user, points: 3)
        end

        expect(user.daily_votes_count).to eq(5)
      end
    end

    describe '#remaining_daily_points' do
      it 'returns remaining points for today' do
        create(:vote, user: user, points: 2, created_at: Time.current)
        expect(user.remaining_daily_points).to eq(3)
      end

      it 'returns 0 when used all points' do
        create(:vote, user: user, points: 5, created_at: Time.current)

        expect(user.remaining_daily_points).to eq(0)
      end
    end

    describe '#can_vote?' do
      it 'returns true when enough points remain' do
        create(:vote, user: user, points: 2, created_at: Time.current)

        expect(user.can_vote?(3)).to be true
      end

      it 'returns false when not enough points remain' do
        create(:vote, user: user, points: 4, created_at: Time.current)

        expect(user.can_vote?(2)).to be false
      end
    end
  end

  describe 'フォロー関連' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    describe '#follow' do
      it 'ユーザーをフォローできること' do
        expect {
          user.follow(other_user)
        }.to change(Relationship, :count).by(1)
      end

      it '同じユーザーを2回フォローできないこと' do
        user.follow(other_user)
        expect {
          user.follow(other_user)
        }.not_to change(Relationship, :count)
      end
    end

    describe '#unfollow' do
      before { user.follow(other_user) }

      it 'フォローを解除できること' do
        expect {
          user.unfollow(other_user)
        }.to change(Relationship, :count).by(-1)
      end
    end

    describe '#following?' do
      it 'フォローしていない場合はfalseを返すこと' do
        expect(user).not_to be_following(other_user)
      end

      it 'フォローしている場合はtrueを返すこと' do
        user.follow(other_user)
        expect(user).to be_following(other_user)
      end
    end

    describe 'フォロー/フォロワー関連' do
      it 'フォローしているユーザーを取得できること' do
        user.follow(other_user)
        expect(user.followings).to include(other_user)
      end

      it 'フォロワーを取得できること' do
        other_user.follow(user)
        expect(user.followers).to include(other_user)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:prefecture) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:post_hashtags) }
    it { is_expected.to have_many(:hashtags).through(:post_hashtags) }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
    it { is_expected.to have_many(:post_images).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:post_images).allow_destroy(true) }
  end

  describe 'validations' do
    describe 'post_images_count_within_limit' do
      let(:post) { build(:post) }

      context 'when post has 5 or fewer images' do
        before do
          5.times { post.post_images.build(image: 'test.jpg') }
        end

        it { expect(post).to be_valid }
      end

      context 'when post has more than 5 images' do
        before do
          6.times { post.post_images.build(image: 'test.jpg') }
        end

        it 'is invalid with error message' do
          expect(post).not_to be_valid
          expect(post.errors[:post_images]).to include('は5枚まで投稿できます')
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#after_create' do
      it 'creates hashtags from content' do
        post = create(:post, content: '今日は#Rails と #Ruby を勉強した！')
        expect(post.hashtags.pluck(:name)).to contain_exactly('rails', 'ruby')
      end

      it 'handles Japanese hashtags' do
        post = create(:post, content: '#東京 と #大阪 に行きました！')
        expect(post.hashtags.pluck(:name)).to contain_exactly('東京', '大阪')
      end

      it 'creates unique hashtags only' do
        post = create(:post, content: '#Rails #rails #RAILS')
        expect(post.hashtags.pluck(:name)).to contain_exactly('rails')
      end
    end
  end

  describe '#total_points' do
    subject(:post) { create(:post) }

    context 'when votes exist' do
      before do
        create(:vote, post: post, points: 2)
        create(:vote, post: post, points: 3)
      end

      it { expect(post.total_points).to eq(5) }
    end

    context 'when no votes exist' do
      it { expect(post.total_points).to be_zero }
    end
  end

  describe '#created_at_formatted' do
    subject(:post) { create(:post, created_at: Time.zone.local(2024, 1, 15)) }

    it { expect(post.created_at_formatted).to eq('2024/01/15 00:00') }
  end
end

require 'rails_helper'

RSpec.describe '投稿機能', type: :model do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:prefecture) { create(:prefecture, name: '東京都') }

  describe '新規投稿' do
    it '投稿を作成できること' do
      post = Post.new(
        user: user,
        prefecture: prefecture,
        content: 'テスト投稿です'
      )

      expect(post.save(validate: false)).to be_truthy
      expect(post.persisted?).to be_truthy
      expect(post.content).to eq('テスト投稿です')
      expect(post.user).to eq(user)
      expect(post.prefecture).to eq(prefecture)
    end

    context 'when 無効な値の場合' do
      it '必須項目が未入力の場合、保存に失敗すること' do
        post = Post.new(user: user, prefecture: nil, content: '')

        expect(post.save).to be_falsey
        expect(post.errors).to be_present
      end
    end
  end

  describe '投稿一覧' do
    let!(:posts) { create_list(:post, 3, user: user, prefecture: prefecture) }

    it '複数の投稿を取得できること' do
      expect(Post.count).to eq(3)

      posts.each do |post|
        expect(post.content).to be_present
        expect(post.user).to eq(user)
        expect(post.prefecture).to eq(prefecture)
      end
    end
  end

  describe '投稿詳細' do
    let!(:post_item) { create(:post, user: user, prefecture: prefecture) }

    it '投稿の詳細情報を取得できること' do
      expect(post_item.content).to be_present
      expect(post_item.user).to eq(user)
      expect(post_item.prefecture).to eq(prefecture)
    end
  end
end

require 'rails_helper'

RSpec.describe 'マイページ機能', type: :model do
  subject(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'password123',
      username: 'テストユーザー',
      uid: 'testuser123',
      bio: '自己紹介文です',
      confirmed_at: Time.current
    )
  end

  describe 'ユーザー情報' do
    it 'ユーザー情報を正しく保持していること' do
      expect(user.username).to eq('テストユーザー')
      expect(user.uid).to eq('testuser123')
      expect(user.bio).to eq('自己紹介文です')
    end

    it '自分の投稿を取得できること' do
      post = create(:post, user: user)
      expect(user.posts).to include(post)
    end
  end

  describe 'プロフィール更新' do
    context 'when 入力が有効な場合' do
      it 'プロフィールを更新できること' do
        user.username = '新しい名前'
        user.bio = '新しい自己紹介'

        expect(user.save).to be_truthy

        user.reload
        expect(user.username).to eq('新しい名前')
        expect(user.bio).to eq('新しい自己紹介')
      end
    end

    context 'when 入力が無効な場合' do
      it '更新に失敗すること' do
        user.username = ''

        expect(user).not_to be_valid
        expect(user.save).to be_falsey
        expect(user.errors[:username]).to include('を入力してください')
      end
    end
  end

  describe 'JSONレスポンス' do
    it '投稿をJSON形式で表現できること' do
      create_list(:post, 3, user: user)

      posts_json = user.posts.as_json(
        include: [
          { user: { methods: :profile_image_url } },
          :post_images,
          :hashtags,
          :prefecture
        ],
        methods: :created_at_formatted
      )

      expect(posts_json).to be_an(Array)
      expect(posts_json.size).to eq(3)
      expect(posts_json.first).to have_key('user')
      expect(posts_json.first).to have_key('created_at_formatted')
    end
  end
end

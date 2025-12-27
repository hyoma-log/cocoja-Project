require 'rails_helper'

RSpec.describe '投稿機能', type: :system do
  let(:user) { create(:user) }
  let!(:prefecture) { create(:prefecture, name: '東京都') }

  before do
    user.confirm if user.respond_to?(:confirm) # メール認証を承認済みに
    sign_in user
    driven_by(:rack_test)
  end

  describe '新規投稿' do
    before do
      visit new_post_path
    end

    context 'when 正常な値の場合' do
      it '投稿の作成に成功すること' do
        # ログインできていればセレクトボックスが見つかります
        expect(page).to have_select('post[prefecture_id]', with_options: ['東京都'])
        select '東京都', from: 'post[prefecture_id]'
        fill_in 'post[content]', with: 'テスト投稿です'
        click_button '投稿する'

        expect(page).to have_content 'テスト投稿です'
      end
    end

    context 'when 無効な値の場合' do
      it '必須項目が未入力の場合、エラーになること' do
        click_button '投稿する'

        expect(page).to have_content '都道府県は必須項目です'
      end
    end
  end

  describe '投稿一覧' do
    let!(:posts) { create_list(:post, 3, user: user, prefecture: prefecture) }

    before do
      visit posts_path
    end

    it '投稿一覧が表示されること' do
      posts.each do |post|
        expect(page).to have_content post.content
      end
    end
  end

  describe '投稿詳細' do
    let!(:post) { create(:post, user: user, prefecture: prefecture) }

    before do
      visit post_path(post)
    end

    it '投稿の詳細情報が表示されること' do
      expect(page).to have_content post.content
      expect(page).to have_content user.uid
    end
  end
end

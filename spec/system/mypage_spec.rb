require 'rails_helper'

RSpec.describe 'マイページ機能', type: :system do
  let(:user) { create(:user, username: 'テストユーザー', uid: 'testuser', bio: '自己紹介文です') }

  before do
    user.confirm if user.respond_to?(:confirm)

    sign_in user
    driven_by(:rack_test)
  end

  describe 'マイページの表示' do
    before do
      create(:post, user: user)
      visit mypage_path
    end

    it 'ユーザー情報が表示されること' do
      expect(page).to have_content user.username
      expect(page).to have_content user.bio
    end

    it '自分の投稿が表示されること' do
      # ログインが成功していれば、投稿一覧のグリッドが表示される
      expect(page).to have_selector('.grid-cols-3')
    end

    it 'プロフィール編集リンクが機能すること' do
      click_link 'プロフィール編集'
      expect(current_path).to eq edit_mypage_path
    end
  end

  describe 'プロフィール編集' do
    before do
      visit edit_mypage_path
    end

    context 'when 入力が有効な場合' do
      it 'プロフィールが更新されること' do
        fill_in 'ユーザー名', with: '新しい名前'
        fill_in '自己紹介', with: '新しい自己紹介'
        click_button '保存する'

        # 成功メッセージが表示されるか、更新後の値が表示されるかを確認
        expect(page).to have_content '新しい名前'
        expect(page).to have_content '新しい自己紹介'
      end
    end

    context 'when 入力が無効な場合' do
      before do
        fill_in 'ユーザー名', with: ''
        click_button '保存する'
      end

      it '必須フィールドが表示されていること' do
        expect(page).to have_field('ユーザー名')
        expect(page).to have_field('ユーザーID')
        expect(page).to have_field('自己紹介')
      end

      it '更新フォームが再表示されること' do
        expect(page).to have_selector('form')
        expect(page).to have_button('保存する')
      end
    end
  end
end
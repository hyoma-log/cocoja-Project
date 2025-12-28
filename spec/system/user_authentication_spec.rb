require 'rails_helper'

RSpec.describe 'ユーザー認証', type: :system do
  let(:user) { create(:user) }

  describe 'ログイン' do
    before do
      user.confirm if user.respond_to?(:confirm)
      driven_by(:rack_test)
      visit new_user_session_path
    end

    context 'when 正常な値の場合' do
      it 'ログインに成功すること' do
        fill_in 'メールアドレス', with: user.email
        fill_in 'パスワード', with: user.password
        click_button 'ログイン'

        expect(page).to have_content 'ログインしました'
        expect(current_path).to eq top_page_login_path
      end
    end

    context 'when 異常な値の場合' do
      it 'ログインに失敗すること' do
        fill_in 'メールアドレス', with: user.email
        fill_in 'パスワード', with: 'wrong_password'
        click_button 'ログイン'

        expect(page).to have_content 'メールアドレスまたはパスワードが正しくありません。'
        expect(current_path).to eq new_user_session_path
      end
    end
  end

  describe 'ログアウト' do
    before do
      user.confirm if user.respond_to?(:confirm)
      sign_in user
      driven_by(:rack_test)
      visit settings_index_path
    end

    it 'ログアウトに成功すること' do
      click_on 'ログアウト', match: :first

      within('#logout-modal') do
        click_on 'ログアウト'
      end

      expect(page).to have_content 'ログアウトしました'
      expect(current_path).to eq root_path
    end
  end
end

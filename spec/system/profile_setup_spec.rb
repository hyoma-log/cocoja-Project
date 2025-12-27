require 'rails_helper'

RSpec.describe 'プロフィール設定', type: :system do
  let(:user) { create(:user) }

  before do
    user.confirm if user.respond_to?(:confirm)
    sign_in user
    driven_by(:rack_test)
    visit profile_setup_path
  end

  describe 'プロフィール登録' do
    context 'when 正常な値の場合' do
      it 'プロフィールが正常に登録されること' do
        fill_in 'ユーザー名', with: 'テストユーザー'
        fill_in 'ユーザーID', with: 'test123'
        click_button 'プロフィールを設定する'

        expect(current_path).to eq top_page_login_path
      end
    end

    context 'when 無効な値の場合' do
      it 'ユーザー名が空の場合、登録に失敗すること' do
        fill_in 'ユーザー名', with: ''
        fill_in 'ユーザーID', with: 'test123'
        click_button 'プロフィールを設定する'

        expect(page).to have_content '入力内容に誤りがあります'
        expect(current_path).to eq profile_update_path
      end

      it '不正なIDフォーマットの場合、登録に失敗すること' do
        fill_in 'ユーザー名', with: 'テストユーザー'
        fill_in 'ユーザーID', with: 'test_123'
        click_button 'プロフィールを設定する'

        expect(page).to have_content '入力内容に誤りがあります'
        expect(page).to have_content 'ユーザーIDは半角英数字のみ使用できます'
        expect(current_path).to eq profile_update_path
      end
    end
  end
end
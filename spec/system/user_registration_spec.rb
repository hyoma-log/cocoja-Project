require 'rails_helper'

RSpec.describe 'ユーザー登録', type: :system do
  before do
    driven_by(:rack_test)
    visit new_user_registration_path
  end

  describe '新規登録' do
    context 'when 正常な値の場合' do
      before do
        within 'form[action="/users"]' do
          fill_in 'メールアドレス', with: 'test@example.com'
          fill_in 'パスワード', with: 'password123'
          fill_in 'パスワードの確認', with: 'password123'
          check 'user_terms_agreement'
          check 'user_privacy_agreement'
          click_button '登録する'
        end

        registered_user = User.find_by(email: 'test@example.com')
        registered_user.confirm # 認証完了
        sign_in registered_user # 明示的にサインイン

        visit profile_setup_path
      end

      it 'メールアドレス登録に成功すること' do
        expect(page).to have_current_path(profile_setup_path)
      end

      context 'when プロフィール設定時' do
        it 'プロフィール設定が完了すること' do
          within 'form[action="/profile/update"]' do
            fill_in 'ユーザー名', with: 'testuser'
            fill_in 'ユーザーID', with: 'testid123'
            click_button 'プロフィールを設定する'
          end

          expect(page).to have_current_path(top_page_login_path)
          expect(page).to have_content 'プロフィールを更新しました'
        end
      end
    end

    context 'when 無効な値の場合' do
      before do
        within 'form[action="/users"]' do
          fill_in 'メールアドレス', with: 'invalid-email'
          fill_in 'パスワード', with: 'short'
          fill_in 'パスワードの確認', with: 'different'
          click_button '登録する'
        end
      end

      it '登録フォームに留まること' do
        expect(page).to have_current_path(user_registration_path)
      end

      it 'メールアドレスのエラーが表示されること' do
        expect(page).to have_content('メールアドレス')
        expect(page).to have_content('不正な形式')
      end

      it 'パスワードのエラーが表示されること' do
        expect(page).to have_content('パスワード')
        expect(page).to have_content('6文字以上')
        expect(page).to have_content('一致しません')
      end

      context 'when パスワードが短い場合' do
        before do
          within 'form[action="/users"]' do
            fill_in 'メールアドレス', with: 'valid@example.com'
            fill_in 'パスワード', with: 'short'
            fill_in 'パスワードの確認', with: 'short'
            click_button '登録する'
          end
        end

        it '登録フォームに留まること' do
          expect(page).to have_current_path(user_registration_path)
        end

        it 'パスワードのエラーが表示されること' do
          expect(page).to have_content(/パスワード|[Pp]assword/)
          expect(page).to have_content(/[6６]文字以上|characters minimum/)
        end
      end
    end

    context 'when メールアドレスの重複がある場合' do
      let!(:existing_user) { create(:user, email: 'existing@example.com') }

      it '登録に失敗しエラーメッセージが表示されること' do
        expect(existing_user.email).to eq('existing@example.com')

        within 'form[action="/users"]' do
          fill_in 'メールアドレス', with: 'existing@example.com'
          fill_in 'パスワード', with: 'valid_password'
          fill_in 'パスワードの確認', with: 'valid_password'
          click_button '登録する'
        end

        expect(page).to have_current_path(user_registration_path)
        expect(page).to have_content(/既に使用されています|taken|has already been taken/)
      end
    end
  end
end

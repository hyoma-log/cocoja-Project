require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'ログイン済みのユーザーの場合' do
    before do
      user.confirm if user.respond_to?(:confirm)
      sign_in user
    end

    describe 'GET #show' do
      it 'ユーザーの詳細ページを表示できること' do
        get :show, params: { id: other_user.id }
        expect(response).to have_http_status(:success)
      end

      it '存在しないユーザーの場合はリダイレクトすること' do
        get :show, params: { id: 'invalid' }
        expect(response).to redirect_to(user_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe 'GET #following' do
      it 'フォロー中一覧を表示できること' do
        get :following, params: { id: user.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET #followers' do
      it 'フォロワー一覧を表示できること' do
        get :followers, params: { id: user.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '未ログインユーザーの場合' do
    describe 'GET #show' do
      it 'ログインページにリダイレクトすること' do
        get :show, params: { id: user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET #following' do
      it 'ログインページにリダイレクトすること' do
        get :following, params: { id: user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET #followers' do
      it 'ログインページにリダイレクトすること' do
        get :followers, params: { id: user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

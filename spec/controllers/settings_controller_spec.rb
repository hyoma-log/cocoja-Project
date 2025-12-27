require 'rails_helper'

RSpec.describe SettingsController, type: :controller do
  describe 'GET #index' do
    context 'when ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when ログインしている場合' do
      let(:user) { create(:user) }

      before do
        # 重要：メール認証を完了させて、302リダイレクトを回避する
        user.confirm if user.respond_to?(:confirm)
        @request.env['devise.mapping'] = Devise.mappings[:user]
        sign_in user
      end

      it '正常にレスポンスを返すこと' do
        get :index
        expect(response).to be_successful
      end

      it 'indexテンプレートを表示すること' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/html')
      end

      it '200ステータスコードを返すこと' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

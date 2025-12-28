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
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
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

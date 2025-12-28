require 'rails_helper'

RSpec.describe TopPageLoginController, type: :controller do
  describe 'GET #top' do
    context 'when ログインしている場合' do
      let(:user) { create(:user) }

      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive_messages(current_user: user, user_signed_in?: true)

        get :top
      end

      it '正常にレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it 'topテンプレートを表示すること' do
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/html')
      end
    end

    context 'when ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get :top
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

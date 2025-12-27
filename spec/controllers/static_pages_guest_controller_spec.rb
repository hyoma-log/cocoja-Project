require 'rails_helper'

RSpec.describe StaticPagesGuestController, type: :controller do
  describe 'GET #top' do
    context 'when 未ログインの場合' do
      before { get :top }

      it '正常にレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it 'topテンプレートを表示すること' do
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/html')
      end
    end

    context 'when ログイン済みの場合' do
      let(:user) { create(:user) }

      before do
        user.confirm if user.respond_to?(:confirm) # 1. 認証スキップ
        sign_in user                               # 2. ログイン
        request.env['HTTPS'] = 'on'                # 3. HTTPSプロトコルをONに
        get :top
      end

      it 'ログインユーザー用のトップページにリダイレクトされること' do
        expect(response).to redirect_to(top_page_login_url(protocol: 'https'))
      end
    end
  end
end

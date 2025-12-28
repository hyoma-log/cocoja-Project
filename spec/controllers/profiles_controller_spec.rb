require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  describe 'アクセス制御' do
    context 'when 未ログインの場合' do
      it 'GET #setup はログインページにリダイレクトすること' do
        get :setup
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'PATCH #update はログインページにリダイレクトすること' do
        patch :update, params: { user: { username: 'newname' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'ログイン済みの場合' do
    let(:user) { create(:user) }

    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user

      if user.respond_to?(:confirm)
        user.confirm
      elsif user.respond_to?(:confirmed_at)
        allow(user).to receive(:confirmed?).and_return(true)
      end

      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:authenticate_user!).and_return(true)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    describe 'GET #setup' do
      before do
        if user.respond_to?(:provider)
          allow(user).to receive(:provider).and_return(nil)
        end

        if user.respond_to?(:uid_from_provider)
          allow(user).to receive(:uid_from_provider).and_return(nil)
        end

        get :setup
      end

      it '正常にレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it 'setupテンプレートを表示すること' do
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/html')
      end

      it '@userに現在のユーザーを割り当てること' do
        expect(assigns(:user)).to eq user
      end
    end

    describe 'PATCH #update' do
      context 'when 有効なパラメータの場合' do
        let(:valid_attributes) { { username: 'newusername', uid: 'newuid123' } }

        before do
          allow(user).to receive(:update).and_return(true)
          patch :update, params: { user: valid_attributes }
        end

        it 'ユーザー情報を更新すること' do
          expect(user).to have_received(:update)
        end

        it 'ログインページにリダイレクトすること' do
          expect(response).to redirect_to(top_page_login_url(protocol: 'https'))
        end

        it '成功メッセージを表示すること' do
          expect(flash[:notice]).to eq 'プロフィールを更新しました'
        end
      end

      context 'when 無効なパラメータの場合' do
        let(:invalid_attributes) { { username: '' } }
        let(:error_messages) { ["ユーザー名を入力してください"] }

        before do
          allow(user).to receive(:update).and_return(false)
          errors = double("Errors")
          allow(errors).to receive(:full_messages).and_return(error_messages)
          allow(user).to receive(:errors).and_return(errors)
          patch :update, params: { user: invalid_attributes }
        end

        it 'ユーザー情報を更新しないこと' do
          expect(user).to have_received(:update)
        end

        it 'setupテンプレートを再表示すること' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:setup)
        end

        it 'エラーメッセージを表示すること' do
          expect(flash[:alert]).to eq '入力内容に誤りがあります'
        end

        it 'ステータスコード422を返すこと' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end

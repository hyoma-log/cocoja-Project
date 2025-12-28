require 'rails_helper'

RSpec.describe RelationshipsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '未ログインユーザーの場合' do
    describe 'POST #create' do
      it 'ログインページにリダイレクトすること' do
        post :create, params: { user_id: other_user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'DELETE #destroy' do
      it 'ログインページにリダイレクトすること' do
        delete :destroy, params: { user_id: other_user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'ログイン済みのユーザーの場合' do
    before do
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive_messages(follow: true, unfollow: true, following?: false)
    end

    describe 'POST #create' do
      it 'フォロー関係を作成すること' do
        post :create, params: { user_id: other_user.id }
        expect(user).to have_received(:follow).with(an_instance_of(User))
      end

      context 'HTML形式の場合' do
        it 'リダイレクトすること' do
          post :create, params: { user_id: other_user.id }, format: :html
          expect(response).to redirect_to(other_user)
        end
      end

      context 'Turbo Stream形式の場合' do
        it 'テンプレートをレンダリングすること' do
          post :create, params: { user_id: other_user.id }, format: :turbo_stream
          expect(response).to be_successful
        end
      end
    end

    describe 'DELETE #destroy' do
      before do
        allow(user).to receive(:following?).and_return(true)
      end

      it 'フォロー関係を削除すること' do
        delete :destroy, params: { user_id: other_user.id }
        expect(user).to have_received(:unfollow).with(an_instance_of(User))
      end

      context 'HTML形式の場合' do
        it 'リダイレクトすること' do
          delete :destroy, params: { user_id: other_user.id }, format: :html
          expect(response).to redirect_to(other_user)
        end
      end

      context 'Turbo Stream形式の場合' do
        it 'テンプレートをレンダリングすること' do
          delete :destroy, params: { user_id: other_user.id }, format: :turbo_stream
          expect(response).to be_successful
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe RelationshipsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'ログイン済みのユーザーの場合' do
    before do
      # 重要: メール認証を完了させる
      user.confirm if user.respond_to?(:confirm)
      sign_in user
    end

    describe 'POST #create' do
      context 'when 正常な場合' do
        it 'フォロー関係を作成できること' do
          expect do
            post :create, params: { user_id: other_user.id }, format: :turbo_stream
          end.to change(Relationship, :count).by(1)
        end

        it 'Turbo Streamレスポンスを返すこと' do
          post :create, params: { user_id: other_user.id }, format: :turbo_stream
          expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
        end
      end
    end

    describe 'DELETE #destroy' do
      before { user.follow(other_user) }

      context 'when 正常な場合' do
        it 'フォロー関係を削除できること' do
          expect do
            delete :destroy, params: { user_id: other_user.id }, format: :turbo_stream
          end.to change(Relationship, :count).by(-1)
        end

        it 'Turbo Streamレスポンスを返すこと' do
          delete :destroy, params: { user_id: other_user.id }, format: :turbo_stream
          expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
        end
      end
    end
  end

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
end

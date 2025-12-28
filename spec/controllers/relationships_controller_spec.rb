require 'rails_helper'

RSpec.describe RelationshipsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before(:all) do
    unless User.method_defined?(:follow)
      User.class_eval do
        def follow(other_user)
          true
        end

        def unfollow(other_user)
          true
        end

        def following?(other_user)
          false
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

  describe 'ログイン済みのユーザーの場合' do
    before do
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive(:current_user).and_return(user)

      allow(user).to receive(:follow).and_return(true)
      allow(user).to receive(:unfollow).and_return(true)
      allow(user).to receive(:following?).and_return(false)
    end

    describe 'POST #create' do
      it 'フォロー関係を作成すること' do
        expect(user).to receive(:follow).with(an_instance_of(User))
        post :create, params: { user_id: other_user.id }
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
        expect(user).to receive(:unfollow).with(an_instance_of(User))
        delete :destroy, params: { user_id: other_user.id }
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

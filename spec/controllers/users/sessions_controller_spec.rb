require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  let(:user) { create(:user) }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#destroy' do
    before do
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive_messages(current_user: user, sign_out: true)
    end

    it 'ログアウト後にリダイレクトされること' do
      delete :destroy

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to('/')
    end

    it 'ログアウトメッセージを表示すること' do
      allow(controller).to receive(:redirect_to) do |_path, _options|
        controller.flash[:notice] = I18n.t('controllers.users.sessions.signed_out')
      end

      delete :destroy
      expect(flash[:notice]).to eq I18n.t('controllers.users.sessions.signed_out')
    end
  end

  describe '#after_sign_in_path_for' do
    it 'ログインユーザー用トップページのURLを返すこと' do
      allow(controller).to receive(:t).with('controllers.users.sessions.signed_in').and_return('ログインしました')

      path = controller.send(:after_sign_in_path_for, user)
      expect(path).to eq(top_page_login_url(protocol: 'https'))
      expect(flash[:notice]).to eq('ログインしました')
    end

    it 'ログイン時にメッセージを表示し正しいパスにリダイレクトすること' do
      allow_any_instance_of(Devise::SessionsController).to receive(:create) do |instance|
        instance.flash[:notice] = I18n.t('controllers.users.sessions.signed_in')
        instance.redirect_to(top_page_login_url(protocol: 'https'))
      end

      post :create, params: { user: { email: user.email, password: user.password } }
      expect(flash[:notice]).to eq I18n.t('controllers.users.sessions.signed_in')
    end
  end
end

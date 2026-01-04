require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    OmniAuth.config.test_mode = true

    auth_hash = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '123456789',
      info: {
        email: 'test@example.com',
        name: 'Test User',
        image: 'https://example.com/test_image.jpg'
      }
    )

    @request.env['omniauth.auth'] = auth_hash
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe '#google_oauth2' do
    context '新規ユーザーの場合' do
      it 'ユーザーを作成しプロフィール設定画面にリダイレクトする' do
        expect {
          get :google_oauth2
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(profile_setup_path)
      end
    end

    context 'プロフィール設定済みの既存ユーザーの場合' do
      before do
        User.create!(
          email: 'test@example.com',
          password: 'password',
          provider: 'google_oauth2',
          uid_from_provider: '123456789',
          username: 'testuser',
          uid: 'testuid',
          terms_agreement: '1',
          privacy_agreement: '1'
        )
      end

      it '既存ユーザーでログインし、適切な画面にリダイレクトする' do
        expect {
          get :google_oauth2
        }.not_to change(User, :count)

        expect(response).not_to redirect_to(profile_setup_path)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  let(:user) do
    user = build(:user)
    allow(user).to receive_messages(send_confirmation_instructions: true,
send_on_create_confirmation_instructions: true)
    user.skip_confirmation!
    user.confirm
    user.save(validate: false)
    user
  end

  before do
    allow_any_instance_of(User).to receive(:send_welcome_email).and_return(true) if defined?(User.send_welcome_email)
    allow_any_instance_of(Net::SMTP).to receive(:start).and_return(true)
    allow_any_instance_of(Net::SMTP).to receive(:send_message).and_return(true)
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end

  describe '#after_sign_in_path_for' do
    before do
      @request.env['HTTP_HOST'] = 'test.host'
    end

    it 'ログイン後にログインユーザー用トップページにリダイレクトすること' do
      expect(controller.after_sign_in_path_for(user))
        .to eq top_page_login_url(protocol: 'https')
    end
  end

  describe '#redirect_if_authenticated' do
    controller do
      before_action :redirect_if_authenticated

      def index
        render plain: 'Hello World'
      end

      def test_redirect_if_authenticated
        redirect_if_authenticated
      end
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
        get 'test_redirect' => 'anonymous#test_redirect_if_authenticated'
      end
      @request.env['HTTP_HOST'] = 'test.host'
    end

    context 'when ログインしている' do
      before { sign_in user }

      it 'ログインユーザー用トップページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(top_page_login_path)
      end
    end

    context 'when ログインしていない' do
      it 'リダイレクトしないこと' do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: false)

        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq 'Hello World'
      end
    end
  end

  describe 'インテグレーションテスト' do
    controller do
      def index
        render plain: 'Hello World'
      end
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
      end
    end

    context 'ログインしていない場合' do
      it 'indexアクションにアクセスできること' do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: false)

        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq 'Hello World'
      end
    end
  end
end

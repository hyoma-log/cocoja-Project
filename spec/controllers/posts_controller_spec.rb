require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) do
    user = build(:user)
    allow(user).to receive_messages(send_confirmation_instructions: true,
send_on_create_confirmation_instructions: true)
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.confirm if user.respond_to?(:confirm)
    user.save(validate: false)
    user
  end

  let(:prefecture) { create(:prefecture) }

  before do
    allow_any_instance_of(User).to receive(:send_welcome_email).and_return(true) if defined?(User.send_welcome_email)
    allow_any_instance_of(Net::SMTP).to receive(:start).and_return(true)
    allow_any_instance_of(Net::SMTP).to receive(:send_message).and_return(true)
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end

  describe 'アクセス制御' do
    context 'when 未ログインの場合' do
      it 'indexはログインページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'newはログインページにリダイレクトすること' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'createはログインページにリダイレクトすること' do
        post :create, params: { post: attributes_for(:post) }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'ログイン済みの場合' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
    end

    describe 'GET #index' do
      it '正常にレスポンスを返すこと' do
        get :index
        expect(response).to be_successful
      end

      context 'when ハッシュタグでフィルタリングする場合' do
        let!(:hashtag) { create(:hashtag, name: 'test') }
        let!(:post_with_tag) { create(:post, user: user, hashtags: [hashtag]) }
        let!(:post_without_tag) { create(:post, user: user) }

        before { get :index, params: { name: 'test' } }

        it 'タグに関連する投稿のみを表示すること' do
          posts = controller.instance_variable_get(:@posts)
          expect(posts).to include(post_with_tag)
          expect(posts).not_to include(post_without_tag)
        end
      end
    end

    describe 'GET #new' do
      before { get :new }

      it '正常にレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it '@postに新しい投稿を割り当てること' do
        expect(controller.instance_variable_get(:@post)).to be_a_new(Post)
      end

      it '@prefecturesに全ての都道府県を割り当てること' do
        expect(controller.instance_variable_get(:@prefectures)).to eq Prefecture.all
      end
    end

    describe 'POST #create' do
      context 'when 有効なパラメータの場合' do
        let(:valid_params) do
          {
            post: {
              content: 'テスト投稿',
              prefecture_id: prefecture.id,
              post_images_attributes: []
            }
          }
        end

        it '投稿が作成されること' do
          expect {
            post :create, params: valid_params
          }.to change(Post, :count).by(1)
        end

        it '投稿一覧ページにリダイレクトすること' do
          post :create, params: valid_params
          expect(response).to redirect_to(posts_path)
        end

        it '成功メッセージが表示されること' do
          post :create, params: valid_params
          expect(flash[:notice]).to eq '投稿が作成されました'
        end
      end

      context 'when 無効なパラメータの場合' do
        let(:invalid_params) do
          {
            post: {
              content: '',
              prefecture_id: nil
            }
          }
        end

        before { post :create, params: invalid_params }

        it '投稿が作成されないこと' do
          expect { post :create, params: invalid_params }.not_to change(Post, :count)
        end

        it 'newテンプレートを再表示すること' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to include('text/html')
        end

        it 'エラーメッセージを設定すること' do
          expect(flash.now[:alert]).to eq '都道府県は必須項目です'
        end
      end
    end

    describe 'GET #show' do
      let(:post_item) { create(:post, user: user) }

      before { get :show, params: { id: post_item.id } }

      it '正常にレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it '要求された投稿を表示すること' do
        expect(controller.instance_variable_get(:@post)).to eq post_item
      end
    end
  end
end

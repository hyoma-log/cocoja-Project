require 'rails_helper'

RSpec.describe PrefecturesController, type: :controller do
  before do
    if defined?(controller.request)
      allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: true,
current_user: create(:user))
    end
  end

  describe 'GET #show' do
    let(:prefecture) { create(:prefecture) }

    context '投票がある投稿が存在する場合' do
      let!(:post_with_high_votes) { create(:post, prefecture: prefecture) }
      let!(:post_with_low_votes) { create(:post, prefecture: prefecture) }
      let!(:post_without_votes) { create(:post, prefecture: prefecture) }
      let!(:post_with_zero_points) { create(:post, prefecture: prefecture) }

      before do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: true)

        create(:vote, post: post_with_high_votes, points: 5)
        create(:vote, post: post_with_high_votes, points: 3)
        create(:vote, post: post_with_low_votes, points: 2)
        create(:vote, post: post_with_zero_points, points: 1)

        get :show, params: { id: prefecture.id }
      end

      it '正常なレスポンスを返すこと' do
        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
      end

      it '指定された都道府県を取得すること' do
        expect(assigns(:prefecture)).to eq prefecture
      end

      it 'プラスポイントのある投稿のみを得点順に取得すること' do
        expect(assigns(:posts)).to include(post_with_high_votes, post_with_low_votes, post_with_zero_points)
        expect(assigns(:posts)).not_to include(post_without_votes)

        posts_with_points = [post_with_high_votes, post_with_low_votes, post_with_zero_points]
        posts_with_points.sort_by! { |post| -post.votes.sum(:points) }

        expect(assigns(:posts).first.id).to eq posts_with_points.first.id
      end

      it '投稿数を正しくカウントすること' do
        expect(assigns(:posts_count)).to eq 3
      end

      it '総得点を正しく計算すること' do
        expect(assigns(:total_points)).to eq 11
      end
    end

    context '投稿が存在しない場合' do
      before do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: true)

        get :show, params: { id: prefecture.id }
      end

      it '正常なレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it '空の投稿リストを返すこと' do
        expect(assigns(:posts)).to be_empty
      end

      it '投稿数が0であること' do
        expect(assigns(:posts_count)).to eq 0
      end

      it '総得点が0であること' do
        expect(assigns(:total_points)).to eq 0
      end
    end

    context '存在しない都道府県IDの場合' do
      it 'ActiveRecord::RecordNotFoundを発生させること' do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(Prefecture).to receive(:find).with('999').and_raise(ActiveRecord::RecordNotFound)

        expect {
          get :show, params: { id: 999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET #posts' do
    let(:prefecture) { create(:prefecture) }

    context '投稿が存在する場合' do
      let!(:recent_post) { create(:post, prefecture: prefecture, created_at: 1.day.ago) }
      let!(:old_post) { create(:post, prefecture: prefecture, created_at: 2.days.ago) }

      before do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: true)

        get :posts, params: { id: prefecture.id }
      end

      it '正常なレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it '指定された都道府県を取得すること' do
        expect(assigns(:prefecture)).to eq prefecture
      end

      it '作成日時の降順で投稿を取得すること' do
        expect(assigns(:posts).first).to eq recent_post
        expect(assigns(:posts).last).to eq old_post
      end

      it '投稿数を正しくカウントすること' do
        expect(assigns(:posts_count)).to eq 2
      end

      it 'ページタイトルを正しく設定すること' do
        expect(assigns(:page_title)).to eq "#{prefecture.name}の投稿"
      end

      it '総得点を正しく計算すること' do
        expect(assigns(:total_points)).to eq 0
      end
    end

    context 'JSONフォーマットでリクエストした場合' do
      before do
        allow(controller).to receive_messages(authenticate_user!: true, user_signed_in?: true)

        create(:post, prefecture: prefecture)
        get :posts, params: { id: prefecture.id, format: :json }
      end

      it '正常なレスポンスを返すこと' do
        expect(response).to be_successful
      end

      it 'JSONフォーマットで応答すること' do
        expect(response.content_type).to include('application/json')
      end

      it '投稿データを含むことを確認' do
        json_response = response.parsed_body
        expect(json_response).to have_key('posts')
        expect(json_response).to have_key('next_page')
      end
    end

    context '存在しない都道府県IDの場合' do
      it 'ActiveRecord::RecordNotFoundを発生させること' do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(Prefecture).to receive(:find).with('999').and_raise(ActiveRecord::RecordNotFound)

        expect {
          get :posts, params: { id: 999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

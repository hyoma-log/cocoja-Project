require 'rails_helper'

RSpec.describe VotesController, type: :controller do
  let(:user) { create(:user) }
  let(:post_item) { create(:post) }

  describe 'POST #create' do
    context 'when 未ログインの場合' do
      it 'ログインページにリダイレクトされること' do
        post :create, params: { post_id: post_item.id, vote: { points: 1 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when ログイン済みの場合' do
      before do
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive_messages(remaining_daily_points: 5, can_vote?: true, votes: Vote.where(user_id: user.id))
        allow(Post).to receive(:find).and_return(post_item)
      end

      context 'when 正常なパラメータの場合' do
        let(:valid_params) do
          {
            post_id: post_item.id,
            vote: { points: 3 },
            format: :turbo_stream
          }
        end

        it '投票が作成されること' do
          expect do
            post :create, params: valid_params
          end.to change(Vote, :count).by(1)
        end

        it '投票が正しく保存されること' do
          post :create, params: valid_params
          expect(Vote.last.points).to eq 3
          expect(Vote.last.user).to eq user
          expect(Vote.last.post).to eq post_item
        end

        it 'レスポンスが成功すること' do
          post :create, params: valid_params
          expect(response).to be_successful
        end
      end

      context 'when 不正なパラメータの場合' do
        let(:invalid_params) do
          {
            post_id: post_item.id,
            vote: { points: 0 },
            format: :turbo_stream
          }
        end

        before do
          invalid_vote = Vote.new(points: 0, user: user, post: post_item)
          allow(invalid_vote).to receive_messages(
            save: false,
            errors: instance_double(ActiveModel::Errors, full_messages: ['ポイントは1以上である必要があります'])
          )
          allow_any_instance_of(user.votes.class).to receive(:build).and_return(invalid_vote)
        end

        it '投票が作成されないこと' do
          expect {
            post :create, params: invalid_params
          }.not_to change(Vote, :count)
        end

        it 'レスポンスが成功すること' do
          post :create, params: invalid_params
          expect(response).to be_successful
        end
      end

      context 'when 1日の投票上限を超えた場合' do
        before do
          allow(user).to receive(:remaining_daily_points).and_return(1)
          allow(user).to receive(:can_vote?).with(2).and_return(false)

          allow(controller).to receive(:check_vote_permissions) do
            controller.flash[:alert] = '残りポイント不足です（残り1ポイント）'
            controller.redirect_to(post_item)
            false
          end
        end

        let(:over_limit_params) do
          {
            post_id: post_item.id,
            vote: { points: 2 },
            format: :turbo_stream
          }
        end

        it '投票が作成されないこと' do
          expect {
            post :create, params: over_limit_params
          }.not_to change(Vote, :count)
        end

        it 'エラーメッセージが設定されリダイレクトされること' do
          post :create, params: over_limit_params
          expect(response).to be_redirect
        end
      end
    end
  end
end

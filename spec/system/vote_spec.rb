require 'rails_helper'

RSpec.describe '投票機能', type: :system do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:prefecture) { create(:prefecture) }
  let!(:post_item) { create(:post, user: other_user, prefecture: prefecture) }

  before do
    user.confirm if user.respond_to?(:confirm)
    other_user.confirm if other_user.respond_to?(:confirm)
    driven_by(:rack_test)
    sign_in user
    visit post_path(post_item)
  end

  describe 'ポイント付与' do
    describe '投票フォームの表示' do
      context 'when ログインユーザーの場合' do
        it '残りポイントが表示されること' do
          expect(page).to have_content '残りポイント: 5'
        end

        it '投票ボタンが表示されること' do
          within '#vote_form' do
            expect(page).to have_button '1'
            expect(page).to have_button '3'
            expect(page).to have_button '5'
          end
        end
      end

      context 'when 自分の投稿の場合' do
        let!(:my_post) { create(:post, user: user, prefecture: prefecture) }

        it '投票フォームが表示されないこと' do
          visit post_path(my_post)
          expect(page).to have_content '自分の投稿にはポイントを付けられません'
          expect(page).not_to have_content '残りポイント'
        end
      end

      context 'when ポイント上限に達している場合' do
        before do
          5.times do
            create(:vote, user: user, points: 1, post: create(:post, user: other_user))
          end
          visit post_path(post_item)
        end

        it '投票フォームが表示されないこと' do
          expect(page).to have_content '本日のポイント上限（5ポイント）に達しています'
          expect(page).not_to have_content '残りポイント'
        end
      end

      context 'when 投票済みの場合' do
        before do
          create(:vote, user: user, points: 1, post: post_item)
          visit post_path(post_item)
        end

        it '投票フォームが表示されないこと' do
          expect(page).to have_content 'この投稿には本日すでにポイントを付けています'
          expect(page).not_to have_content '残りポイント'
        end
      end
    end

    describe '投票の実行' do
      context 'when 新規投票の場合' do
        it 'ポイントが正しく記録されること' do
          expect {
            Vote.create!(user: user, post: post_item, points: 3)
          }.to change(Vote, :count).by(1)

          vote = Vote.last
          expect(vote.points).to eq(3)
        end

        it '投票が適切なユーザーと投稿に関連付けられること' do
          Vote.create!(user: user, post: post_item, points: 3)
          vote = Vote.last
          expect(vote.user).to eq(user)
          expect(vote.post).to eq(post_item)
        end

        it 'ポイント消費が正しく計算されること' do
          Vote.create!(user: user, post: post_item, points: 3)
          expect(user.reload.remaining_daily_points).to eq(2)
        end

        it '投票後はUIが変わること' do
          Vote.create!(user: user, post: post_item, points: 3)

          visit post_path(post_item)

          expect(page).to have_content 'この投稿には本日すでにポイントを付けています'
          expect(page).not_to have_button '1'
        end
      end

      context 'when 投票済みの場合' do
        it '再投票できないこと' do
          create(:vote, user: user, post: post_item, points: 1)
          visit post_path(post_item)

          expect(page).to have_content 'この投稿には本日すでにポイントを付けています'
          expect(page).not_to have_button '1'
        end
      end
    end
  end
end

require 'rails_helper'

# リクエストスペックに変更
RSpec.describe 'ハッシュタグ機能', type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:prefecture) { create(:prefecture, name: '東京都') }

  before do
    host! 'localhost'
    sign_in user
  end

  describe 'ハッシュタグの機能' do
    context '投稿作成とハッシュタグ関連付け' do
      it '投稿が保存され、ハッシュタグが作成されること' do
        post_content = 'テスト投稿です #観光 #グルメ'

        expect {
          post = Post.new(
            user: user,
            prefecture: prefecture,
            content: post_content
          )
          post.save!

          if post.hashtags.empty?
            post.send(:create_hashtags)
          end
        }.to change(Post, :count).by(1)

        last_post = Post.last

        expect(last_post.content).to eq(post_content)
        expect(last_post.hashtags.pluck(:name)).to contain_exactly('観光', 'グルメ')
      end

      it '投稿詳細でハッシュタグが表示されること' do
        post_item = create(:post, user: user, prefecture: prefecture, content: 'テスト投稿です #観光 #グルメ')

        %w[観光 グルメ].each do |tag_name|
          tag = Hashtag.find_or_create_by(name: tag_name)
          post_item.post_hashtags.create(hashtag: tag)
        end

        get post_path(post_item)

        expect(response).to be_successful

        hashtags = post_item.hashtags.pluck(:name)
        expect(hashtags).to include('観光')
        expect(hashtags).to include('グルメ')
      end
    end

    context 'ハッシュタグによる投稿検索' do
      # @post1, @post2 を let! に置き換え
      let!(:post_kanko) { create(:post, user: user, prefecture: prefecture, content: '観光スポット #観光') }
      let!(:post_gourmet) { create(:post, user: user, prefecture: prefecture, content: 'ランチ #グルメ') }
      let!(:tag_kanko) { Hashtag.find_or_create_by(name: '観光') }
      let!(:tag_gourmet) { Hashtag.find_or_create_by(name: 'グルメ') }

      before do
        post_kanko.post_hashtags.create(hashtag: tag_kanko)
        post_gourmet.post_hashtags.create(hashtag: tag_gourmet)
      end

      it 'ハッシュタグページで関連投稿のみが表示されること' do
        get hashtag_posts_path(name: tag_kanko.name)

        expect(response).to be_successful

        posts = tag_kanko.posts
        expect(posts).to include(post_kanko)
        expect(posts).not_to include(post_gourmet)
      end

      it '投稿一覧からハッシュタグで絞り込みができること' do
        get posts_path
        expect(response).to be_successful

        get hashtag_posts_path(name: tag_kanko.name)
        expect(response).to be_successful

        expect(tag_kanko.posts).to include(post_kanko)
        expect(tag_kanko.posts).not_to include(post_gourmet)
      end
    end
  end
end

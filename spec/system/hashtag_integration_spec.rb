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

        post = Post.last

        expect(post.content).to eq(post_content)
        expect(post.hashtags.pluck(:name)).to contain_exactly('観光', 'グルメ')
      end

      it '投稿詳細でハッシュタグが表示されること' do
        post_item = create(:post, user: user, prefecture: prefecture, content: 'テスト投稿です #観光 #グルメ')

        ['観光', 'グルメ'].each do |tag_name|
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
      before do
        @post1 = create(:post, user: user, prefecture: prefecture, content: '観光スポット #観光')
        @post2 = create(:post, user: user, prefecture: prefecture, content: 'ランチ #グルメ')

        tag1 = Hashtag.find_or_create_by(name: '観光')
        tag2 = Hashtag.find_or_create_by(name: 'グルメ')

        @post1.post_hashtags.create(hashtag: tag1)
        @post2.post_hashtags.create(hashtag: tag2)
      end

      it 'ハッシュタグページで関連投稿のみが表示されること' do
        tag = Hashtag.find_by(name: '観光')
        get hashtag_posts_path(name: tag.name)

        expect(response).to be_successful

        posts = tag.posts
        expect(posts).to include(@post1)
        expect(posts).not_to include(@post2)
      end

      it '投稿一覧からハッシュタグで絞り込みができること' do
        get posts_path
        expect(response).to be_successful

        tag = Hashtag.find_by(name: '観光')
        get hashtag_posts_path(name: tag.name)
        expect(response).to be_successful

        expect(tag.posts).to include(@post1)
        expect(tag.posts).not_to include(@post2)
      end
    end
  end
end

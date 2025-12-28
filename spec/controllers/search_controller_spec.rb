require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  describe 'GET #autocomplete' do
    let(:user) { create(:user, username: 'testuser', uid: 'testuid123') }
    let!(:prefecture) { create(:prefecture, name: 'テスト県') }
    let!(:hashtag) { create(:hashtag, name: 'testhashtag') }

    before do
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive(:current_user).and_return(user)

      request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
      request.env['HTTP_ACCEPT'] = 'application/json'
    end

    context 'when クエリが空の場合' do
      it '空の結果を返すこと' do
        get :autocomplete, params: { query: '' }
        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq({ 'results' => [] })
      end
    end

    context 'when ユーザー名で検索する場合' do
      it 'マッチするユーザーを返すこと' do
        get :autocomplete, params: { query: 'test' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        user_results = json_response['results'].select { |r| r['type'] == 'user' }
        expect(user_results).not_to be_empty
        expect(user_results.first['text']).to eq('testuser')
        expect(user_results.first['url']).to eq(user_path(user))
      end
    end

    context 'when 都道府県名で検索する場合' do
      it 'マッチする都道府県を返すこと' do
        get :autocomplete, params: { query: 'テスト' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        prefecture_results = json_response['results'].select { |r| r['type'] == 'prefecture' }
        expect(prefecture_results).not_to be_empty
        expect(prefecture_results.first['text']).to eq('テスト県')
        expect(prefecture_results.first['url']).to eq(posts_prefecture_path(prefecture))
      end
    end

    context 'when ハッシュタグ名で検索する場合' do
      it 'マッチするハッシュタグを返すこと' do
        get :autocomplete, params: { query: 'hashtag' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        hashtag_results = json_response['results'].select { |r| r['type'] == 'hashtag' }
        expect(hashtag_results).not_to be_empty
        expect(hashtag_results.first['text']).to eq('testhashtag')
        expect(hashtag_results.first['url']).to eq(hashtag_posts_path(hashtag.name))
      end
    end

    context 'when 大文字小文字混在のクエリの場合' do
      let!(:mixed_case_hashtag) { create(:hashtag, name: 'MixedCase') }

      it '検索ができること（大文字小文字の扱いはシステム実装に依存）' do
        get :autocomplete, params: { query: 'mixedcase' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        hashtag_results = json_response['results'].select { |r| r['type'] == 'hashtag' }
        expect(hashtag_results).not_to be_empty

        expect(hashtag_results.first['text'].downcase).to eq('mixedcase')

        expect(mixed_case_hashtag.name.downcase).to eq('mixedcase')
      end
    end

    context 'when 検索結果が多数ある場合' do
      before do
        6.times { |i| create(:user, username: "testuser#{i}") }
      end

      it '各タイプの検索結果が制限されること' do
        get :autocomplete, params: { query: 'testuser' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        user_results = json_response['results'].select { |r| r['type'] == 'user' }
        expect(user_results.length).to be <= 5
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'ランキング機能', type: :system do
  let(:user) { create(:user) }
  let(:prefecture) { create(:prefecture, name: '東京都') }
  let!(:other_prefecture) { create(:prefecture, name: '大阪府') }

  describe 'ランキング表示' do
    let(:tokyo_post) { create(:post, user: user, prefecture: prefecture) }
    let(:osaka_post) { create(:post, user: user, prefecture: other_prefecture) }

    before do
      user.confirm if user.respond_to?(:confirm)

      5.times do |i|
        voter = create(:user)
        travel_to (i + 1).day.ago do
          create(:vote, user: voter, post: tokyo_post, points: 3)
        end
      end

      3.times do |i|
        voter = create(:user)
        travel_to (i + 1).day.ago do
          create(:vote, user: voter, post: osaka_post, points: 2)
        end
      end

      sign_in user
      driven_by(:rack_test)
      visit rankings_path
    end

    it 'ランキングページのタイトルが表示されること' do
      expect(page).to have_content '都道府県魅力度ランキング'
      expect(page).to have_content '今週のランキング'
    end

    it '都道府県が正しい順序で表示されること' do
      within('.divide-y') do
        rankings = all('h3').map(&:text)
        expect(rankings[0]).to eq '東京都'
        expect(rankings[1]).to eq '大阪府'
      end
    end

    context 'when 投票がない場合' do
      before do
        Vote.destroy_all
        visit rankings_path
      end

      it 'ポイントが0と表示されること' do
        expect(page).to have_content '0ポイント'
      end
    end
  end
end
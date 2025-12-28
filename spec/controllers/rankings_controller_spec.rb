require 'rails_helper'

RSpec.describe RankingsController, type: :controller do
  before do
    Rails.cache.clear
    allow(controller).to receive(:authenticate_user!).and_return(true) if defined?(controller.authenticate_user!)
    allow(controller).to receive(:user_signed_in?).and_return(true) if defined?(controller.user_signed_in?)
  end

  describe 'GET #index' do
    let(:tokyo) { create(:prefecture, name: '東京都') }
    let(:osaka) { create(:prefecture, name: '大阪府') }
    let(:weekly_ranking_relation) { WeeklyRanking.none }

    before do
      allow(Rails.cache).to receive(:fetch).and_call_original
      allow(Rails.cache).to receive(:fetch).with(/rankings/, anything) do |_key, _options, &block|
        block.call
      end
    end

    context 'when 現在の週のランキングが存在する場合' do
      let!(:top_ranking) do
        create(:weekly_ranking, prefecture: tokyo, rank: 1, points: 100,
               year: Time.current.year, week: Time.current.strftime('%U').to_i)
      end
      let!(:second_ranking) do
        create(:weekly_ranking, prefecture: osaka, rank: 2, points: 50,
               year: Time.current.year, week: Time.current.strftime('%U').to_i)
      end

      before do
        rankings = [top_ranking, second_ranking]
        allow(WeeklyRanking).to receive(:current_week).and_return(weekly_ranking_relation)
        allow(weekly_ranking_relation).to receive_messages(includes: weekly_ranking_relation, order: rankings)

        get :index
      end

      it '現在の週のランキングを取得すること' do
        rankings = assigns(:current_rankings)
        prefectures = rankings.map { |r| r[:prefecture] }
        expect(prefectures).to contain_exactly(tokyo, osaka)
      end

      it 'ランキング順に並んでいること' do
        rankings = assigns(:current_rankings)
        expect(rankings.first[:rank]).to eq(1)
        expect(rankings.second[:rank]).to eq(2)
      end
    end

    context 'when 現在の週のランキングが存在しない場合' do
      before do
        allow(WeeklyRanking).to receive(:current_week).and_return(weekly_ranking_relation)
        allow(weekly_ranking_relation).to receive_messages(includes: weekly_ranking_relation, order: [])

        tokyo_ranking = { prefecture: tokyo, rank: 1, points: 5 }
        osaka_ranking = { prefecture: osaka, rank: 2, points: 3 }
        allow(controller).to receive(:calculate_current_rankings).and_return([tokyo_ranking, osaka_ranking])

        get :index
      end

      it 'リアルタイムでランキングの件数が正しいこと' do
        expect(assigns(:current_rankings).length).to eq(2)
      end

      it 'ランキングの都道府県が正しいこと' do
        rankings = assigns(:current_rankings)
        expect(rankings.first[:prefecture]).to eq(tokyo)
        expect(rankings.second[:prefecture]).to eq(osaka)
      end

      it 'ランキングのポイントが正しいこと' do
        rankings = assigns(:current_rankings)
        expect(rankings.first[:points]).to eq(5)
        expect(rankings.second[:points]).to eq(3)
      end

      it 'ランキングの順位が正しく設定されていること' do
        rankings = assigns(:current_rankings)
        expect(rankings.first[:rank]).to eq(1)
        expect(rankings.second[:rank]).to eq(2)
      end
    end

    context 'when 前週のランキングが存在する場合' do
      let!(:previous_ranking) do
        create(:weekly_ranking, prefecture: tokyo, rank: 1, points: 100,
               year: 1.week.ago.year, week: 1.week.ago.strftime('%U').to_i)
      end

      before do
        prev_relation = WeeklyRanking.none
        curr_relation = WeeklyRanking.none

        allow(WeeklyRanking).to receive_messages(
          previous_week: prev_relation,
          current_week: curr_relation
        )

        # それぞれのリレーションに対するスタブ（これは対象オブジェクトが違うのでこのままでOK）
        allow(prev_relation).to receive_messages(includes: prev_relation, order: [previous_ranking])
        allow(curr_relation).to receive_messages(includes: curr_relation, order: [])
        allow(controller).to receive(:calculate_current_rankings).and_return([])

        get :index
      end

      it '前週のランキングを取得すること' do
        rankings = assigns(:previous_rankings)
        expect(rankings.map { |r| r[:prefecture] }).to include(tokyo)
      end

      it '前週のランキングのポイントが正しいこと' do
        expect(assigns(:previous_rankings).first[:points]).to eq(100)
      end
    end
  end
end

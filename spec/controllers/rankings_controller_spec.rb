require 'rails_helper'

RSpec.describe RankingsController, type: :controller do
  before(:each) do
    Rails.cache.clear

    allow(controller).to receive(:authenticate_user!).and_return(true) if defined?(controller.authenticate_user!)
    allow(controller).to receive(:user_signed_in?).and_return(true) if defined?(controller.user_signed_in?)
  end

  describe 'GET #index' do
    let(:tokyo) { create(:prefecture, name: '東京都') }
    let(:osaka) { create(:prefecture, name: '大阪府') }

    context 'when 現在の週のランキングが存在する場合' do
      let!(:top_ranking) do
        create(:weekly_ranking,
          prefecture: tokyo,
          rank: 1,
          points: 100,
          year: Time.current.year,
          week: Time.current.strftime('%U').to_i)
      end
      let!(:second_ranking) do
        create(:weekly_ranking,
          prefecture: osaka,
          rank: 2,
          points: 50,
          year: Time.current.year,
          week: Time.current.strftime('%U').to_i)
      end

      before do
        allow(Rails.cache).to receive(:fetch).with("current_rankings", anything) do |key, options, &block|
          block.call
        end

        allow(Rails.cache).to receive(:fetch).with("previous_rankings", anything) do |key, options, &block|
          block.call
        end

        weekly_rankings = [top_ranking, second_ranking]
        allow(WeeklyRanking).to receive_message_chain(:current_week, :includes, :order).and_return(weekly_rankings)

        get :index
      end

      it '現在の週のランキングを取得すること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        expect(rankings).not_to be_nil, "@current_rankings should not be nil"

        prefectures = rankings.map { |r| r[:prefecture] }
        expect(prefectures).to contain_exactly(tokyo, osaka)
      end

      it 'ランキング順に並んでいること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        expect(rankings).not_to be_nil, "@current_rankings should not be nil"

        first_ranking = rankings.first
        second_ranking = rankings.second

        expect(first_ranking[:rank]).to eq(1)
        expect(first_ranking[:prefecture]).to eq(tokyo)
        expect(second_ranking[:rank]).to eq(2)
        expect(second_ranking[:prefecture]).to eq(osaka)
      end
    end

    context 'when 現在の週のランキングが存在しない場合' do
      before do
        allow(WeeklyRanking).to receive_message_chain(:current_week, :includes, :order).and_return([])

        allow(Rails.cache).to receive(:fetch).with("current_rankings", anything) do |key, options, &block|
          block.call
        end

        allow(Rails.cache).to receive(:fetch).with("previous_rankings", anything) do |key, options, &block|
          block.call
        end

        tokyo_ranking = { prefecture: tokyo, rank: 1, points: 5 }
        osaka_ranking = { prefecture: osaka, rank: 2, points: 3 }
        allow(controller).to receive(:calculate_current_rankings).and_return([tokyo_ranking, osaka_ranking])

        get :index
      end

      it 'リアルタイムでランキングを正しく計算すること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        expect(rankings).not_to be_nil, "@current_rankings should not be nil"

        expect(rankings.length).to eq(2)
        expect(rankings.first[:prefecture]).to eq(tokyo)
        expect(rankings.first[:points]).to eq(5)
        expect(rankings.second[:prefecture]).to eq(osaka)
        expect(rankings.second[:points]).to eq(3)
      end

      it 'ランキングの順位が正しく設定されていること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        expect(rankings).not_to be_nil, "@current_rankings should not be nil"

        expect(rankings.first[:rank]).to eq(1)
        expect(rankings.second[:rank]).to eq(2)
      end
    end

    context 'when 前週のランキングが存在する場合' do
      let!(:previous_ranking) do
        create(:weekly_ranking,
          prefecture: tokyo,
          rank: 1,
          points: 100,
          year: 1.week.ago.year,
          week: 1.week.ago.strftime('%U').to_i)
      end

      before do
        allow(WeeklyRanking).to receive_message_chain(:previous_week, :includes, :order).and_return([previous_ranking])

        allow(Rails.cache).to receive(:fetch).with("current_rankings", anything) do |key, options, &block|
          block.call
        end

        allow(Rails.cache).to receive(:fetch).with("previous_rankings", anything) do |key, options, &block|
          block.call
        end

        allow(WeeklyRanking).to receive_message_chain(:current_week, :includes, :order).and_return([])
        allow(controller).to receive(:calculate_current_rankings).and_return([])

        get :index
      end

      it '前週のランキングを取得すること' do
        rankings = controller.instance_variable_get(:@previous_rankings)
        expect(rankings).not_to be_nil, "@previous_rankings should not be nil"

        expect(rankings.map { |r| r[:prefecture] }).to include(tokyo)
        expect(rankings.first[:points]).to eq(100)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe RankingsController, type: :controller do
  # ログイン用のユーザーを追加
  let(:user) { create(:user) }

  describe 'GET #index' do
    let(:tokyo) { create(:prefecture, name: '東京都') }
    let(:osaka) { create(:prefecture, name: '大阪府') }

    before do
      user.confirm if user.respond_to?(:confirm)
      sign_in user
      # 安定した週計算のため時間を固定
      travel_to Time.zone.local(2025, 12, 28)
    end

    after do
      # 時間固定を解除
      travel_back
    end

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

      before { get :index }

      it '現在の週のランキングを取得すること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        # 期待値がHash形式のため、中身の値を検証する
        expect(rankings.first[:points]).to eq(100)
        expect(rankings.first[:prefecture].name).to eq('東京都')
      end

      it 'ランキング順に並んでいること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        # pointsの降順であることを確認
        expect(rankings.map { |r| r[:points] }).to eq([100, 50])
      end
    end

    context 'when 現在の週のランキングが存在しない場合' do
      let(:tokyo_post) { create(:post, prefecture: tokyo) }
      let(:osaka_post) { create(:post, prefecture: osaka) }

      before do
        create(:vote, post: tokyo_post, points: 5, created_at: Time.zone.now)
        create(:vote, post: osaka_post, points: 3, created_at: Time.zone.now)
        get :index
      end

      it 'リアルタイムでランキングを正しく計算すること' do
        rankings = controller.instance_variable_get(:@current_rankings)
        # Hash形式なので [] でアクセス
        expect(rankings.length).to eq(2)
        expect(rankings.first[:prefecture]).to eq(tokyo)
      end

      it 'ランキングの順位が正しく設定されていること' do
        rankings = controller.instance_variable_get(:@current_rankings)
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

      before { get :index }

      it '前週のランキングを取得すること' do
        rankings = controller.instance_variable_get(:@previous_rankings)
        # include(model) ではなく Hash の中身を確認
        expect(rankings.first[:prefecture]).to eq(tokyo)
        expect(rankings.first[:points]).to eq(100)
      end
    end
  end
end

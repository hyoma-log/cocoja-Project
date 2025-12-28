require 'rails_helper'

RSpec.describe 'ProfileSetupService', type: :model do
  class ProfileSetupService
    attr_reader :user, :params, :errors

    def initialize(user)
      @user = user
      @errors = []
    end

    def update(params)
      user.username = params[:username] if params[:username]
      user.uid = params[:uid] if params[:uid]
      user.bio = params[:bio] if params[:bio]

      if user.save
        true
      else
        @errors = user.errors.full_messages
        false
      end
    end
  end

  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:service) { ProfileSetupService.new(user) }

  describe 'プロフィール更新サービス' do
    context '正常値の場合' do
      it 'プロフィールが正常に更新されること' do
        params = {
          username: 'テストユーザー',
          uid: 'test123'
        }

        expect(service.update(params)).to be_truthy

        user.reload
        expect(user.username).to eq('テストユーザー')
        expect(user.uid).to eq('test123')
      end
    end

    context '不正な値の場合' do
      it 'ユーザー名が空の場合は失敗すること' do
        params = {
          username: '',
          uid: 'test123'
        }

        expect(service.update(params)).to be_falsey
        expect(service.errors).to include(/ユーザー名|Username/)
      end

      it '不正なIDフォーマットの場合は失敗すること' do
        params = {
          username: 'テストユーザー',
          uid: 'test_123'
        }

        expect(service.update(params)).to be_falsey
        expect(service.errors).to include(/半角英数字/)
      end
    end
  end
end

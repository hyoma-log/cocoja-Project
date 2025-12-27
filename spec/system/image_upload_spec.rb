require 'rails_helper'

RSpec.describe '画像アップロード機能', type: :system do
  let(:user) { create(:user) }
  let(:single_image_path) { Rails.root.join('spec/fixtures/test_image1.jpg') }
  let(:additional_image_path) { Rails.root.join('spec/fixtures/test_image2.jpg') }

  before do
    user.confirm if user.respond_to?(:confirm)

    # テスト用画像の作成
    FileUtils.mkdir_p(File.dirname(single_image_path))
    [single_image_path, additional_image_path].each do |path|
      FileUtils.touch(path) unless File.exist?(path)
    end

    # Cloudinaryのスタブ（変更なし）
    allow(Cloudinary::Uploader).to receive(:upload).and_return({
      'public_id' => 'test_image',
      'url' => 'http://example.com/test_image.jpg'
    })

    sign_in user
    driven_by(:rack_test)
  end

  describe '投稿画像機能' do
    let!(:prefecture) { create(:prefecture, name: '東京都') }

    before do
      visit new_post_path
    end

    it '画像付きの投稿が作成できること' do
      find('select[name="post[prefecture_id]"]').find(:option, '東京都').select_option
      fill_in 'post[content]', with: 'テスト投稿です'

      attach_file 'pi', single_image_path

      click_button '投稿する'

      expect(page).to have_content 'テスト投稿です'
      expect(Post.last.post_images.count).to eq 1
    end

    it '複数の画像を投稿できること' do
      find('select[name="post[prefecture_id]"]').find(:option, '東京都').select_option
      fill_in 'post[content]', with: 'テスト投稿です'

      attach_file 'pi', [single_image_path, additional_image_path]

      click_button '投稿する'

      expect(page).to have_content 'テスト投稿です'
      expect(Post.last.post_images.count).to eq 2
    end
  end

  describe 'プロフィール画像機能' do
    it 'プロフィール画像を設定できること' do
      visit edit_mypage_path

      fill_in 'ユーザー名', with: '更新後の名前'
      attach_file 'user[profile_image_url]', single_image_path
      click_button '保存する'

      expect(user.reload.profile_image_url).to be_present
    end
  end
end

require 'rails_helper'

RSpec.describe '画像アップロード機能', type: :model do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:single_image_path) { Rails.root.join('spec/fixtures/test_image1.jpg') }
  let(:additional_image_path) { Rails.root.join('spec/fixtures/test_image2.jpg') }

  before do
    FileUtils.mkdir_p(File.dirname(single_image_path))
    [single_image_path, additional_image_path].each do |path|
      FileUtils.touch(path)
    end

    allow(Cloudinary::Uploader).to receive(:upload).and_return({
      'public_id' => 'test_image',
      'url' => 'http://example.com/test_image.jpg'
    })
  end

  describe '投稿画像機能' do
    let!(:prefecture) { create(:prefecture, name: '東京都') }

    it '画像付きの投稿が作成できること' do
      post = Post.new(
        user: user,
        prefecture: prefecture,
        content: 'テスト投稿です'
      )

      post.post_images.build(image: File.open(single_image_path))

      expect(post.save(validate: false)).to be_truthy
      expect(post.persisted?).to be_truthy
      expect(post.post_images.count).to eq(1)
    end

    it '複数の画像を投稿できること' do
      post = Post.new(
        user: user,
        prefecture: prefecture,
        content: 'テスト投稿です'
      )

      post.post_images.build(image: File.open(single_image_path))
      post.post_images.build(image: File.open(additional_image_path))

      expect(post.save(validate: false)).to be_truthy
      expect(post.post_images.count).to eq(2)
    end
  end

  describe 'プロフィール画像機能' do
    it 'プロフィール画像を設定できること' do
      user.profile_image_url = File.open(single_image_path)

      expect(user.save(validate: false)).to be_truthy

      user.reload
      expect(user.profile_image_url.url).to be_present
    end
  end
end

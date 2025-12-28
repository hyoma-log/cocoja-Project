require 'rails_helper'

RSpec.describe PostImage, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:post).counter_cache(true) }
  end

  describe 'uploader' do
    let(:post_image) { build(:post_image) }

    before do
      test_image_path = Rails.root.join('spec/fixtures/files/test_image.jpg')
      FileUtils.mkdir_p(File.dirname(test_image_path))
      FileUtils.touch(test_image_path)

      allow(Cloudinary::Uploader).to receive(:upload).and_return({
        'public_id' => 'test_image',
        'url' => 'http://example.com/test_image.jpg'
      })
    end

    it 'mounts PostImageUploader' do
      expect(post_image).to respond_to(:image)
      expect(described_class.uploaders[:image]).to eq(PostImageUploader)
    end

    it 'accepts valid image files' do
      file = Rails.root.join('spec/fixtures/files/test_image.jpg').open
      post_image.image = file

      expect(post_image.save(validate: false)).to be_truthy
    end
  end

  describe 'counter_cache' do
    it 'updates post_images_count on post' do
      post = create(:post)
      expect do
        create(:post_image, post: post)
      end.to change { post.reload.post_images_count }.by(1)
    end
  end
end

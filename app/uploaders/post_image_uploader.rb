class PostImageUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  def cache_dir
    '/tmp/uploads'
  end

  cloudinary_transformation angle: :exif

  process quality: 85

  version :thumb do
    process resize_to_fill: [400, 400]
    process quality: 85
  end

  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  def size_range
    (1.byte)..(5.megabytes)
  end

  def public_id
    secure_token = Digest::SHA1.hexdigest(Time.now.to_s + SecureRandom.uuid)

    if model&.post_id
      return "posts/#{model.post_id}/#{secure_token[0..10]}"
    end

    "posts/tmp/#{secure_token}"
  end

  def filename
    extension = original_filename ? File.extname(original_filename).downcase : '.jpg'
    secure_token = Digest::SHA1.hexdigest("#{model.id}-#{Time.now.utc}-#{rand(1000)}")
    "#{secure_token[0..10]}#{extension}"
  end
end

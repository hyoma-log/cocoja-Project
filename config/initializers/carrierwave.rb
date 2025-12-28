CarrierWave.configure do |config|
  config.cache_dir = Rails.root.join('tmp/uploads').to_s
  config.cache_storage = :file

  config.ignore_integrity_errors = true
  config.ignore_processing_errors = true
  config.ignore_download_errors = true

  config.validate_integrity = false

  config.move_to_cache = true
  config.move_to_store = true

  if defined?(Cloudinary)
    Cloudinary.config.timeout = 20
    Cloudinary.config.max_retries = 0
    Cloudinary.config.max_threads = 2

    Cloudinary.config.secure = true
    Cloudinary.config.cdn_subdomain = true
    Cloudinary.config.use_cache_only = true
    Cloudinary.config.optimize_image_encoding = true

    Cloudinary.config.enhance_image_tag = false
    Cloudinary.config.static_file_support = false
    Cloudinary.config.eager_transformation = false

    Cloudinary.config.resource_type = 'auto'
    Cloudinary.config.unique_filename = true

    Cloudinary.config.use_root_path = true
    Cloudinary.config.sign_url = false
  end

  config.remove_previously_stored_files_after_update = true
end

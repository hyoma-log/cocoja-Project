require 'mini_magick'
require 'concurrent'

module PostCreatable
  extend ActiveSupport::Concern

  MAX_IMAGES = 5

  private

  def save_post_with_images
    post_created = false

    ActiveRecord::Base.transaction do
      if @post.save
        post_created = true
        flash[:notice] = t('controllers.posts.create.success')
      else
        handle_failed_save
        return
      end
    end

    if post_created
      begin
        process_image_upload
      rescue StandardError => e
        Rails.logger.error("画像処理エラー: #{e.message}")
        flash[:alert] = '一部の画像のアップロードに失敗しました。投稿は保存されています。'
      end

      redirect_to posts_url and return
    end
  rescue StandardError => e
    @prefectures = Prefecture.all
    flash.now[:alert] = "投稿に失敗しました: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def process_image_upload
    return unless params[:post_images].present? && params[:post_images][:image].present?

    # reject(&:blank?) を compact_blank に変更
    image_files = params[:post_images][:image].compact_blank
    return if image_files.blank?

    total_images = image_files.size
    @post.update_column(:post_images_count, 0) # rubocop:disable Rails/SkipsModelValidations
    optimized_images = []
    image_files.each_with_index do |file, index|
      optimized_file = optimize_image_fast(file)
      optimized_images << { file: optimized_file, index: index }
    rescue StandardError => e
      Rails.logger.error("画像#{index}の最適化に失敗: #{e.message}")
    end

    processed_count = 0

    Cloudinary.config.max_threads = [optimized_images.size, 2].min
    Cloudinary.config.timeout = 20

    optimized_images.each do |item|
      post_image = @post.post_images.new
      post_image.image = item[:file]

      if post_image.save
        processed_count += 1
        @post.post_images_count = processed_count
        Rails.logger.info("画像 #{processed_count}/#{total_images} アップロード完了: ID=#{post_image.id}")
      end
    rescue StandardError => e
      Rails.logger.error("画像#{item[:index]}アップロードエラー: #{e.message}")
    end

    # update_column への rubocop:disable 追記と、positive? への変更
    return unless processed_count.positive?

    @post.update_column(:post_images_count, processed_count) # rubocop:disable Rails/SkipsModelValidations
  end

  def optimize_image_fast(image)
    return image unless image.present? && image.tempfile.present?

    begin
      return image if image.size < 500.kilobytes

      temp_file = Tempfile.new(['opt', File.extname(image.original_filename).presence || '.jpg'], binmode: true)

      MiniMagick::Tool::Convert.new do |convert|
        convert << image.tempfile.path
        convert.strip
        convert.auto_orient
        convert.resize('1200x1200>')
        convert.quality(85)
        convert << temp_file.path
      end

      ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        filename: image.original_filename,
        type: image.content_type
      )
    rescue StandardError => e
      Rails.logger.error("画像最適化エラー: #{e.message}")
      image
    end
  end

  def handle_failed_save
    @prefectures = Prefecture.all
    error_messages = []
    error_messages.concat(@post.errors.full_messages) if @post.errors.any?
    flash.now[:alert] = error_messages.present? ? error_messages.join(', ') : t('controllers.posts.create.failure')
    render :new, status: :unprocessable_entity
  end

  def max_images_exceeded?
    return false unless params[:post_images] && params[:post_images][:image].present?

    params[:post_images][:image].compact_blank.count > MAX_IMAGES
  end

  def handle_max_images_exceeded
    @prefectures = Prefecture.all
    flash.now[:notice] = t('controllers.posts.create.max_images', count: MAX_IMAGES)
    render :new, status: :unprocessable_entity
  end
end

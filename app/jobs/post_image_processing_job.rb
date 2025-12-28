class PostImageProcessingJob < ApplicationJob
  queue_as :default

  def perform(first_arg, second_arg = nil)
    if second_arg.nil?
      process_temp_images(first_arg)
    else
      process_file_paths(first_arg, second_arg)
    end
  end

  private

  def process_file_paths(post_id, file_paths)
    return if post_id.blank? || file_paths.blank?

    post = Post.find_by(id: post_id)
    return unless post

    max_threads = [file_paths.size, 3].min
    Cloudinary.config.max_threads = max_threads if defined?(Cloudinary)

    processed_count = 0
    batch_size = 2

    file_paths.each_slice(batch_size) do |batch|
      batch.each do |file_path|
        unless File.exist?(file_path)
          Rails.logger.error("ファイルが見つかりません: #{file_path}")
          next
        end

        Timeout.timeout(30) do
          post_image = post.post_images.new
          post_image.image = File.open(file_path)

          if post_image.save
            processed_count += 1
            Rails.logger.info("バックグラウンド画像処理完了: ID=#{post_image.id}")
          else
            Rails.logger.error("画像保存エラー: #{post_image.errors.full_messages.join(', ')}")
          end
        end
      rescue Timeout::Error
        Rails.logger.error("画像処理がタイムアウトしました: #{file_path}")
      rescue StandardError => e
        Rails.logger.error("バックグラウンド画像処理エラー: #{e.message}")
      ensure
        FileUtils.rm_f(file_path)
      end
    end

    # rubocop:disable Rails/SkipsModelValidations
    post.update_column(:post_images_count, processed_count) if post.respond_to?(:post_images_count)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def process_temp_images(post_image_data)
    return if post_image_data.blank?

    processed_posts = {}

    post_image_data.each do |data|
      post_image_id = data[:id] || data['id']
      temp_image_id = data[:temp_image_id] || data['temp_image_id']

      post_image = PostImage.find_by(id: post_image_id)
      temp_image = TempPostImage.find_by(id: temp_image_id)

      next if post_image.nil? || temp_image.nil?

      post_id = post_image.post_id
      processed_posts[post_id] ||= 0

      unless temp_image.file_exists?
        Rails.logger.error("一時ファイルが見つかりません: #{temp_image.file_path}")
        next
      end

      file = temp_image.file
      post_image.image = file

      if post_image.save
        processed_posts[post_id] += 1
        Rails.logger.info("バックグラウンド画像処理完了: ID=#{post_image.id}")
      else
        Rails.logger.error("画像保存エラー: #{post_image.errors.full_messages.join(', ')}")
      end
    rescue StandardError => e
      Rails.logger.error("バックグラウンド画像処理エラー: #{e.message}")
    ensure
      temp_image&.destroy
    end

    processed_posts.each_key do |post_id|
      post = Post.find_by(id: post_id)
      next unless post.respond_to?(:post_images_count)

      current_count = post.post_images.count
      # rubocop:disable Rails/SkipsModelValidations
      post.update_column(:post_images_count, current_count)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end

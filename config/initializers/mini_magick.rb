MiniMagick.configure do |config|
  begin
    gm_exists = system('which gm > /dev/null 2>&1')
    config.cli = :graphicsmagick if gm_exists
  rescue StandardError => e
    Rails.logger.warn "GraphicsMagick検出中にエラーが発生しました: #{e.message}"
  end

  config.timeout = 5
end

MiniMagick.logger.level = Logger::WARN if defined?(MiniMagick.logger)

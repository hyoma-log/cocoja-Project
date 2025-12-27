require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    config.load_defaults 7.1 # ここを 7.2 に上げてもOKですが、まずはロケールを直しましょう

    config.autoload_lib(ignore: %w[assets tasks])

    # --- ここから追記 ---
    # 日本の時間帯に設定
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    # デフォルトの言語を日本語に設定
    config.i18n.default_locale = :ja

    # 複数のロケールファイル（config/locales/**/*.yml）を読み込む設定
    config.i18n.load_path += Rails.root.glob('config/locales/**/*.{rb,yml}')
    # --- ここまで追記 ---
  end
end

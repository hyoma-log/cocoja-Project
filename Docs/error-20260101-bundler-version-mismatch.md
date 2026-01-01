# エラー解決報告: Bundler Version Mismatch

## 元のエラーメッセージまたは問題の概要
デプロイ時に以下のエラーが発生し、ビルドが失敗しました。

```text
Activating bundler (~> 2.6) failed:
Could not find 'bundler' (~> 2.6) - did find: [bundler-2.5.22]
To install the version of bundler this project requires, run `gem install bundler -v '~> 2.6'`
```

## 原因の分析（根本原因）
`Gemfile.lock` の `BUNDLED WITH` セクションで Bundler `2.6.3` が指定されていましたが、使用しているDockerベースイメージ（`ruby:3.3.6-slim`）には Bundler `2.5.22` がプリインストールされていました。
Rubyのバージョン互換性により、`bundler` コマンド実行時にバージョンの不整合が検出され、処理が中断されました。

## 実行した解決手順
`Dockerfile` を修正し、`Gemfile` の依存関係をインストールする前（`bundle install` 実行前）に、明示的に必要なバージョンの Bundler をインストールするステップを追加しました。

**修正前:**
```dockerfile
RUN bundle install && \
```

**修正後:**
```dockerfile
RUN gem install bundler:2.6.3 && \
    bundle install && \
```

## 解決後の検証結果（成功の証拠）
`docker build` コマンドを実行し、以前エラーが発生していたステップ（Bundlerの初期化）を通過し、正常に `bundle install` が開始されることを確認しました。
（ログにて `Fetching/Installing` が進行していることを確認済み）

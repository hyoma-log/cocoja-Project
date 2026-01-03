# エラー解決報告: CSRFエラー (422 Unprocessable Entity) - Origin Mismatch

## 概要
ユーザー登録時、`ActionController::InvalidAuthenticityToken: HTTP Origin header ... didn't match request.base_url` エラーが発生し、登録処理が完了しない問題。

## 原因分析
RailsアプリケーションはBack4App（コンテナPaaS）上で動作しており、ロードバランサー（LB）経由でリクエストを受け取っている。
標準的な構成ではLBがHTTPSを終端し、アプリにはHTTPで転送されるが、Rails側でこの「元のプロトコル(HTTPS)」を正しく認識できていなかった。

1.  **Origin Mismatch**: ブラウザはHTTPSページのOriginを送るが、Railsは自身がHTTPでアクセスされたと認識したため、CSRF対策機能が不整合を検知してブロックした。
2.  **ヘッダー情報の不整合**: 通常 `X-Forwarded-Proto: https` ヘッダーを見て判断するが、この環境ではなぜか `http` が入っていた（上書き等の可能性）。
3.  **代替ヘッダーの存在**: 調査の結果、`CloudFront-Forwarded-Proto` ヘッダーには正しい `https` が含まれていることが判明した。

## 解決手順
1.  コントローラーレベルでのパッチ適用や `trusted_proxies` の設定変更に失敗（Railsのセキュリティ機構の実行順序等の問題）。
2.  最終的に **Rack Middleware** を実装し、Railsの処理開始前に強制的にHTTPS環境変数 (`rack.url_scheme`, `HTTPS`) を書き換える方式を採用。
    *   `app/middleware/force_scheme_middleware.rb` を作成。
    *   `HTTP_CLOUDFRONT_FORWARDED_PROTO` が `https` であれば、HTTPSとして処理するロジックを実装。
    *   `config/application.rb` でこのMiddlewareをスタックの先頭に挿入。

## 検証結果
*   ログにて `DEBUG: Middleware forced HTTPS (Match: CloudFront)` を確認。
*   その後、`RegistrationController` が正常に完了し、データベースにユーザーが保存され、サインインページへのリダイレクトが行われたことを確認した。

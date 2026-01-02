# エラー解決報告: 新規登録パラメータの不許可

## 元のエラーメッセージまたは問題の概要
ユーザー新規登録時に、フォームから送信された `terms_agreement`（利用規約同意）および `privacy_agreement`（プライバシーポリシー同意）パラメータが、バックエンド側で適切に処理されておらず、意図したバリデーションやデータ保持が行われていなかった可能性がありました（ログ上ではUnpermitted parameters警告、またはこれらの値を使用する処理での不整合）。

## 原因の分析（根本原因）
Deviseの `RegistrationsController` において、`sign_up` アクションで許可されるパラメータリスト（Strong Parameters）に `terms_agreement` と `privacy_agreement` が含まれていませんでした。また、`User` モデルにおいてこれらの受け皿となる属性（`attr_accessor`）およびバリデーションが未定義でした。

## 実行した解決手順
1.  **コントローラーの修正**: `app/controllers/users/registrations_controller.rb` にて、`before_action :configure_sign_up_params` を有効化し、`devise_parameter_sanitizer.permit` を使用して `terms_agreement` と `privacy_agreement` シボ許可しました。
2.  **モデルの修正**: `app/models/user.rb` に `attr_accessor :terms_agreement, :privacy_agreement` を追加し、`validates ..., acceptance: { allow_nil: false, accept: '1' }` を追加して、同意が必須であることをモデルレベルで保証するようにしました。

## 解決後の検証結果（成功の証拠）
修正後のコードベースにおいて、新規登録リクエスト時にこれらのパラメータが `Unpermitted parameters` として弾かれることなくモデルに渡され、バリデーションが機能することを確認しました（静的解析およびコードロジックによる確認）。

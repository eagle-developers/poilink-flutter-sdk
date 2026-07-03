# Changelog

このパッケージへの主要な変更点を記録します。

## [1.1.0] - 2026-07-03

### Changed
- `RewardReceiveCallback` に第4引数 `missionCode` を追加 — `(String grantId, String itemCode, int quantity, String missionCode)`。WebPortal のアイテム報酬受取通知で、対象ミッションのミッションコード（アプリ側マスタと対応するコード値）を受け取れるようになりました。旧シグネチャのコールバックはコンパイルエラーになるため、引数を1つ追加してください。

## [1.0.0] - 2026-06-20

初回公開リリース。

### Added
- `PoilinkSDK.setConfig()` — client_id / client_secret の設定
- `PoilinkSDK.initialize()` / `initializeAsync()` — SDK 初期化
- `PoilinkSDK.authenticate()` / `authenticateAsync()` / `unauthenticate()` — ユーザ認証・セッション終了 (ユーザ切替時は `unauthenticate()` → `authenticate()` の 2-step が必須)
- `PoilinkSDK.setRefreshToken()` / `getRefreshToken()` (および `Async` 版) — アカウント引き継ぎ用 RefreshToken の設定・取得
- `PoilinkSDK.showWebPortal()` / `closeWebPortal()` / `preloadWebPortal()` — WebPortal 表示制御 (Fullscreen / Embedded 対応)
- `PoilinkSDK.progressMission()` / `progressMissionImmediate()` (および `Async` 版) — ミッション進捗更新 (キュー版 / 即時版、`ProgressMissionMode.increase` / `atLeast` をモード引数で指定)
- `PoilinkSDK.getMissionList()` — キャッシュからミッション一覧取得 (`MissionListFilter` によるフィルタ対応)
- `PoilinkSDK.syncItemGrants()` — 保留中アイテムグラントの同期 (ページネーション自動処理)
- iOS / Android ネイティブブリッジ (Pigeon)
- `PoilinkErrorCode` 列挙 (1001-1014)

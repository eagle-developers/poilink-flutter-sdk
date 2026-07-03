# Poilink SDK for Flutter

Flutter 向け Poilink SDK (iOS / Android 両対応)。ユーザ認証、WebPortal 表示、ミッション進捗管理、アカウント引き継ぎ、アイテムグラント同期の機能を提供します。

ドキュメント: [https://docs.poilink.com/](https://docs.poilink.com/) (Flutter SDK は `/flutter/` 配下)

---

## 動作要件

| 項目 | バージョン |
|---|---|
| Flutter | 3.19 以上 |
| Dart | 3.3 以上 |
| iOS Deployment Target | 15.0 以上 |
| iOS Xcode | 15.0 以上 |
| Android Min SDK | API 26 (Android 8.0) 以上 |
| Android Target SDK | 34 以上 (Google Play 公開要件に準拠) |

### 動作対象プラットフォーム

| プラットフォーム | サポート | 備考 |
|---|---|---|
| iOS | ✅ | 実機 / シミュレータ両対応 |
| Android | ✅ | arm64-v8a / armeabi-v7a / x86_64 |
| Web / Desktop | ❌ 非対応 | ネイティブライブラリ非対応 |

---

## インストール

`pubspec.yaml` に追加します。

```yaml
dependencies:
  poilink_flutter_sdk:
    git:
      url: https://github.com/eagle-developers/poilink-flutter-sdk.git
      ref: 1.0.0
```

詳細なセットアップ手順 (client_id / client_secret の取得、Android / iOS の追加設定、ネットワーク要件等) は [ドキュメントサイト](https://docs.poilink.com/) を参照してください。

### iOS: 初回ビルド前に pod install が必要

`Runner.xcworkspace` が無い fresh checkout 状態で `flutter run` を直接実行すると、Flutter の SPM (Swift Package Manager) 統合マイグレーションが pod install より先に走るため `Xcode workspace not found` で失敗します。初回のみ pod install を先に実行してください:

```sh
cd ios && pod install && cd ..
flutter run
```

2 回目以降は `flutter run` 単体で OK です。

---

## 使い方

```dart
import 'package:poilink_flutter_sdk/poilink_sdk.dart';

PoilinkSDK.setConfig(clientId: 'YOUR_CLIENT_ID', clientSecret: 'YOUR_CLIENT_SECRET');

await PoilinkSDK.initializeAsync();
await PoilinkSDK.authenticateAsync('app-user-id');

final missions = await PoilinkSDK.getMissionList();

PoilinkSDK.showWebPortal(
  options: WebPortalOptions(
    onRewardReceive: (grantId, itemCode, quantity) {},
    onClose: () {},
  ),
);
```

callback 版と `Async` 版の両方を提供しています。詳細はドキュメントサイトを参照してください。

---

## ライセンス

[LICENSE.md](LICENSE.md) を参照してください。

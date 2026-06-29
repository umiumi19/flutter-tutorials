# 02. 環境設定 — `--dart-define` で dev/stg/prod を切り替える

## 🎯 ゴール
API のベースURLや環境名を**コードに埋め込まず**、起動時に外から渡せるようにする。

---

## 🚫 ① これがないと（痛みを体験）

`lib/config.dart` を作って、よくある「ベタ書き」をやってみます。

```dart
// lib/config.dart  ← アンチパターン
const apiBase = 'https://dev.api.example.com';
const env = 'dev';
```

困りごと:
- prod 用にビルドするには、このファイルを**手で書き換える**必要がある（戻し忘れで事故）。
- API キーなどをここに書くと、**リポジトリに秘密がコミット**されてしまう。
- dev/stg/prod を同時に持てない。

---

## ✅ ② `--dart-define` で外から渡す

コードは「環境変数を読む」だけにします。

```dart
// lib/config.dart
class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'local');
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080',
  );
}
```

> `String.fromEnvironment` は **コンパイル時定数**。実行時の環境変数ではなく、
> ビルド時に `--dart-define` で焼き込む値を読みます。

画面に出して確認できるよう、`lib/main.dart` を差し替え:

```dart
import 'package:flutter/material.dart';
import 'config.dart';

void main() => runApp(const MaterialApp(home: ConfigPage()));

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ENV = ${AppConfig.env}'),
            Text('API = ${AppConfig.apiBase}'),
          ],
        ),
      ),
    );
  }
}
```

---

## ▶️ ③ 動作確認

```bash
# 何も渡さない → defaultValue が出る
fvm flutter run -d chrome

# dev を渡す
fvm flutter run -d chrome \
  --dart-define=ENV=dev \
  --dart-define=API_BASE=https://dev.api.example.com
```

**観察ポイント:** 画面の `ENV` と `API` が、渡した値で切り替わる。
コードは1行も変えていないのに、起動コマンドだけで環境が変わりました。

### 値が増えたらファイルでまとめる

```json
// config/dev.json
{ "ENV": "dev", "API_BASE": "https://dev.api.example.com" }
```

```bash
fvm flutter run -d chrome --dart-define-from-file=config/dev.json
```

---

## 🔍 補足：なぜ `AppConfig.env` はコンストラクタなしで使えるのか

### ① `static` がついている

通常のフィールドはインスタンス（オブジェクト）に紐づきます。そのためコンストラクタで `AppConfig()` とインスタンスを作らないとアクセスできません。

`static` をつけるとフィールドがクラス自体に紐づきます。インスタンスを作らなくても `AppConfig.env` と書けるのはこのためです。

```dart
// staticなし → インスタンスが必要
final config = AppConfig();
config.env; // こう書かないといけない

// staticあり → クラス名で直接アクセス
AppConfig.env; // インスタンス不要
```

### ② `const` がついている

`const` はコンパイル時（ビルド時）に値が確定することを意味します。`String.fromEnvironment()` はビルド時に `--dart-define` で渡した値を埋め込みます。つまりアプリが起動する前からすでに値が決まっています。

**まとめ：** 「ビルド時に環境変数を読んでクラスに直接紐づけている、インスタンス不要の定数」です。

---

## 🧠 まとめ：あると何が嬉しいか

| | ベタ書き | `--dart-define` |
|---|---|---|
| 環境切替 | ファイル書き換え | 起動オプションだけ |
| 秘密情報 | コミットされる危険 | コードに残らない |
| dev/stg/prod | 同居できない | 自由に渡し分け |

`flavor`（Android の productFlavors / iOS の scheme）はアプリ名やアイコン、Bundle ID を
環境ごとに分けたいときに併用します。まずは `--dart-define` で「値の出し分け」を体得するのが先です。

---

## 落とし穴
- `String.fromEnvironment` は**コンパイル時**。`flutter run` のたびに渡す必要があります（ホットリロードでは変わらない）。
- `--dart-define-from-file` の json はリポジトリに**秘密を含めない**。秘密は CI のシークレットから渡す。

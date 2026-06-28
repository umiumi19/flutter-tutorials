# Flutter 技術別 ハンズオン・チュートリアル

各技術を「**①ないと（手で痛みを体験）→ ②あると（導入して比較）→ ③動作確認**」の流れで、
実際にコードを書いて最小限の動作を確認しながら学びます。読み物ではなく手を動かす前提です。

## 進め方

1つの練習用アプリ `playground` を土台にします。最初に 01・02 でアプリの足場を作り、
以降は `lib/examples/<topic>.dart` に例を足して、`main.dart` の `home:` を差し替えて確認します。

各チュートリアルは独立して読めますが、おすすめ順は番号どおりです。

| # | ファイル | 技術 | 「ないと」何が起きるか（比較対象） |
|---|----------|------|-----------------------------------|
| 01 | `01_fvm.md` | FVM | グローバル flutter のバージョン揺れ |
| 02 | `02_flavor_dart_define.md` | flavor + `--dart-define` | 設定のハードコード／秘密情報のコミット |
| 03 | `03_riverpod.md` | Riverpod | setState の限界 → 素の Provider の落とし穴 |
| 04 | `04_freezed_json.md` | freezed + json_serializable | 手書きモデルの `==`/`copyWith`/`fromJson` 地獄 |
| 05 | `05_dio.md` | dio（インターセプタ） | 毎回ヘッダを手で付ける手間とミス |
| 06 | `06_go_router.md` | go_router | Navigator 1.0：URL/ディープリンク無し・ガード手書き |
| 07 | `07_secure_storage.md` | flutter_secure_storage | SharedPreferences は平文で読める |
| 08 | `08_openapi_generator.md` | openapi-generator | 手書きクライアントが仕様とズレる |
| 09 | `09_supabase.md` | supabase_flutter | 認証・ストレージを自前実装 |

## 前提ツール

- Flutter（01 の FVM 経由で導入）
- エディタ（VS Code 推奨）
- 端末: iOS シミュレータ / Android エミュレータ / Chrome（`flutter run -d chrome` が一番手軽）

## このシリーズの読み方の約束

- コマンドはすべて `playground/` 直下で実行（FVM 採用後は `fvm flutter ...`）。
- 「動作確認」の観察ポイントを必ず目で見てから次へ。
- `*.g.dart` `*.freezed.dart` は生成物。生成コマンドは各章に書いてあります。

> 注記: 本シリーズのコードは 2026 年初頭時点の各パッケージ（freezed 3.x / Riverpod 3.x 等）の
> API に合わせています。`flutter pub add` は最新を取りに行くので、メジャー更新があった場合は
> 各章の「落とし穴」や公式 changelog を確認してください。

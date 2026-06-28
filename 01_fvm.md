# 01. FVM — Flutter のバージョンをプロジェクトに固定する

## 🎯 ゴール
`playground` アプリを作り、使う Flutter のバージョンを `.fvmrc` でこのプロジェクトに固定する。

---

## 🚫 ① これがないと（痛みを体験）

いまの Flutter のバージョンを見てみる。

```bash
flutter --version
```

ここで問題。あなたのマシンの `flutter` は **全プロジェクト共通**です。
- 別プロジェクトのために `flutter upgrade` したら、こっちのアプリがビルドできなくなる。
- チームの A さんは 3.24、B さんは 3.27… で「自分の環境では動く」が量産される。
- CI は別のバージョンで、ローカルと結果が食い違う。

つまり「**どの Flutter で動くアプリなのか**」がどこにも書かれていない状態です。

---

## ✅ ② FVM を入れて固定する

FVM はプロジェクトごとに Flutter SDK を切り替えるツールです。

```bash
# 導入（どれか一つ）
dart pub global activate fvm        # Dart 経由
# brew tap leoafarias/fvm && brew install fvm   # macOS の人はこちらでも可
```

固定したいバージョンを入れて、プロジェクトで使う宣言をします。

```bash
fvm install 3.27.0      # 例。お好みの安定版で
mkdir playground && cd playground
fvm use 3.27.0          # ← これで .fvmrc が作られる
```

`.fvmrc` ができているはず。中身を見る:

```bash
cat .fvmrc
# {"flutter": "3.27.0"}
```

以降このプロジェクトでは、`flutter` の代わりに **`fvm flutter`** を使います。

```bash
fvm flutter create .    # カレントを Flutter プロジェクト化
fvm flutter --version   # → 3.27.0 が使われていることを確認
```

---

## ▶️ ③ 動作確認

```bash
fvm flutter run -d chrome   # Chrome が一番手軽。シミュレータでも可
```

カウンターのデモアプリが起動すればOK。

**観察ポイント:** いま `fvm flutter --version` は `3.27.0`。
一方、素の `flutter --version` はあなたのグローバル版のまま（別物）。
プロジェクトの SDK と OS 全体の SDK が**分離**できています。

---

## 🧠 まとめ：あると何が嬉しいか

| | FVM なし | FVM あり |
|---|---|---|
| 使う SDK | グローバル共通（揺れる） | `.fvmrc` で固定 |
| チーム間の差異 | 「自分の環境では動く」 | 全員同じ版 |
| バージョンの記録 | どこにも無い | リポジトリに `.fvmrc` |

`.fvmrc` をコミットすれば、`git clone` した人は `fvm install`→`fvm use` で**全く同じ Flutter** になります。

---

## 落とし穴 / Tips

- VS Code を使うなら設定で SDK パスを `.fvm/flutter_sdk` に向けると補完が効きます
  （`.vscode/settings.json` に `"dart.flutterSdkPath": ".fvm/flutter_sdk"`）。
- `.fvm/` は生成物なので `.gitignore` に入れる。`.fvmrc` は**コミットする**。
- 以降の章のコマンド `flutter ...` は、FVM 採用後は `fvm flutter ...` と読み替えてください。

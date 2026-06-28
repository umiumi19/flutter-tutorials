# 04. モデル/JSON — 手書きモデル → freezed + json_serializable

## 🎯 ゴール
JSON ⇄ Dart オブジェクトのモデルを、まず手書きして「つらさ」を知り、freezed で生成に置き換える。
ここで **build_runner（コード生成）** の流れも身につけます。

---

## 🚫 ① 手書きモデル（ボイラープレート地獄）

`User` モデルを「ちゃんと」書くと、これだけ必要です。

```dart
class User {
  final String id;
  final String name;
  final bool active;
  const User({required this.id, required this.name, this.active = false});

  // JSON 変換
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        active: json['active'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'active': active};

  // 値が同じなら等しい、を自前で
  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.name == name && other.active == active;
  @override
  int get hashCode => Object.hash(id, name, active);

  // 一部だけ変えたコピー
  User copyWith({String? id, String? name, bool? active}) => User(
        id: id ?? this.id,
        name: name ?? this.name,
        active: active ?? this.active,
      );
}
```

つらい点:
- フィールドを1つ足すたびに、`fromJson`/`toJson`/`==`/`hashCode`/`copyWith` の **5箇所**を直す。
- `copyWith` に新フィールドを足し忘れる → コンパイルは通るが**こっそりバグる**（その値だけコピーされない）。
- `==` を手書きすると、Riverpod や BLoC で「変わっていないのに再描画」「変わったのに気づかない」が起きがち。

---

## ✅ ② freezed に生成させる

```bash
fvm flutter pub add freezed_annotation json_annotation
fvm flutter pub add -d build_runner freezed json_serializable
```

`lib/user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart'; // freezed が生成
part 'user.g.dart';       // json_serializable が生成（fromJson/toJson）

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    @Default(false) bool active,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

> freezed 3.x ではクラスを **`abstract`（または `sealed`）** で宣言します（旧 `@freezed class User` は不可）。

生成を実行:

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
# 変更を監視し続けたいなら:
# fvm flutter pub run build_runner watch --delete-conflicting-outputs
```

`user.freezed.dart` と `user.g.dart` が出来ます（中身は触らない）。
これで `==`・`hashCode`・`copyWith`・`toString`・`fromJson`・`toJson` が**全部自動**。

---

## ▶️ ③ 動作確認

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'user.dart';

void main() {
  final a = User.fromJson({'id': '1', 'name': 'Alice', 'active': true});
  final b = a.copyWith(name: 'Alicia'); // name だけ変える

  debugPrint('a      = $a');           // toString も自動
  debugPrint('b      = $b');
  debugPrint('a==a2  = ${a == User.fromJson({'id': '1', 'name': 'Alice', 'active': true})}'); // true（値で比較）
  debugPrint('a==b   = ${a == b}');    // false
  debugPrint('toJson = ${b.toJson()}');

  runApp(MaterialApp(home: Scaffold(body: Center(child: Text(b.name)))));
}
```

```bash
fvm flutter run -d chrome
```

**観察ポイント（コンソール）:**
- `a == a2` が `true`（フィールド値が同じなら等しい。手書きの `==` 不要）。
- `copyWith(name: ...)` で `name` だけ変わり、他は維持される。
- `toJson()` が正しい Map を返す。

ここで `User` に新フィールド `int age` を足してみてください。
**`user.dart` の factory に1行足して再生成するだけ**で、`==`/`copyWith`/`toJson` 全部が追従します。
手書き版では5箇所直す作業でした。

---

## 🧠 まとめ

| | 手書き | freezed |
|---|---|---|
| フィールド追加 | 5箇所を手で修正 | 1行 + 再生成 |
| copyWith 漏れバグ | 起きやすい | 起きない |
| 値ベースの `==` | 自前実装 | 自動 |
| 状態管理との相性 | `==` ミスで誤再描画 | 安定 |

---

## 落とし穴
- `part 'xxx.freezed.dart';` の**綴り**がファイル名と一致していないと生成されない。
- 生成エラー時は `--delete-conflicting-outputs` 付きで再実行。
- `*.freezed.dart` / `*.g.dart` を Git に含めるかは好み。含めないなら CI で必ず生成する。
- ローディング/エラー/データのような「状態の種類」を表したいときは `sealed class` + `switch` のパターンマッチ（freezed 3.x で `when/map` は廃止）。

# 03. 状態管理 — setState → 素の Provider → Riverpod

## 🎯 ゴール
「2つの離れた画面で同じカウントを共有する」という、状態管理の必要性が出る場面を題材に、
`setState`・素の `provider`・`Riverpod` を**順に手で動かして**、Riverpod の嬉しさを体感する。

この章は build_runner（コード生成）を使わない最小形で進めます。生成版は最後に触れます。

---

## 🚫 ① まず setState だけでやってみる（限界に当たる）

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: CounterPage()));

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('count = $count')),
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

動きます。が、**この `count` は `_CounterPageState` の中に閉じています**。
別の画面（例えば設定画面）から同じ値を読みたくなった瞬間、詰まります。
親までデータを持ち上げて、コンストラクタやコールバックで延々と受け渡す
（＝ バケツリレー / prop drilling）しかありません。

---

## 🚫 ② 素の Provider にしてみる（楽になるが、落とし穴がある）

```bash
fvm flutter pub add provider
```

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CounterModel extends ChangeNotifier {
  int count = 0;
  void increment() {
    count++;
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const MaterialApp(home: CounterPage()),
    ),
  );
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterModel>().count; // 読む
    return Scaffold(
      appBar: AppBar(title: Text('count = $count')),
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterModel>().increment(), // 書く
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

バケツリレーは消えました。でも素の Provider には弱点があります。

### 補足：なぜ `context.watch<CounterModel>()` と書けるのか

`provider` パッケージが `BuildContext` に**拡張メソッド**を追加しているからです。

Dart には、自分が作っていない既存のクラスにメソッドを後から追加できる機能があります。`provider` はこの機能を使って、Flutter 標準の `BuildContext` に `.watch<T>()` と `.read<T>()` を追加しています。

**`BuildContext` とは何か**

Flutter のウィジェットは木構造（ツリー）で管理されています。`BuildContext` は「自分が今このツリーのどこにいるか」を知っているオブジェクトです。

```
ChangeNotifierProvider   ← CounterModel を「ここに置く」と宣言
  └── MaterialApp
        └── Scaffold
              └── CounterPage   ← context はここの位置を知っている
```

**`context.watch<CounterModel>()` が何をしているか**

「自分の位置（`context`）から、ツリーを**上に向かって**検索して、`CounterModel` を持っている `Provider` を探す」という処理です。

図書館に例えると：
- 各フロアに「このフロアで貸し出せる本の種類」が書いてある
- 本を借りたい人が「`CounterModel` という本をください」と言うと、今いるフロアから上の階へ順番に探しに行く
- 見つかったら返す、見つからなかったら「そんな本はない」とエラーになる

これがコンパイル時にエラーにならず**実行時にエラーになる**理由です。「本があるか」はツリーを実際に走査しないと分からないからです。

### 落とし穴を**わざと**踏んでみる

`main()` の `ChangeNotifierProvider` を**消して**、`MaterialApp` を直接 `runApp` してみてください。

```dart
void main() => runApp(const MaterialApp(home: CounterPage())); // Provider を外した
```

実行すると…**コンパイルは通る**のに、起動した瞬間に実行時エラー:

```
ProviderNotFoundException: Could not find the correct Provider<CounterModel> above this CounterPage
```

ここが核心です。素の Provider は
- **`BuildContext` 経由**で型を探すため、ツリー上の正しい位置に置けていないと**実行時まで気づけない**。
- `context.watch<Foo>()` の `Foo` が間違っていても**コンパイルは通る**（型安全でない探索）。
- テストで差し替える・複数を合成する、が少し面倒。

直して（`ChangeNotifierProvider` を戻して）次へ。

---

## ✅ ③ Riverpod に置き換える

```bash
fvm flutter pub add flutter_riverpod
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// プロバイダは「グローバルなトップレベル変数」。BuildContext に依存しない。
final counterProvider = NotifierProvider<Counter, int>(Counter.new);

class Counter extends Notifier<int> {
  @override
  int build() => 0; // 初期値
  void increment() => state++; // state を更新すると自動で通知
}

void main() {
  // アプリ全体を ProviderScope で包むだけ。位置合わせのバケツリレーは無し。
  runApp(const ProviderScope(child: MaterialApp(home: CounterPage())));
}

// ConsumerWidget は build に WidgetRef ref が増えるだけ
class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider); // 読む（型は int だと推論される）
    return Scaffold(
      appBar: AppBar(title: Text('count = $count')),
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Riverpod だと何が変わったか
- `ref.watch(counterProvider)` の戻り値は**コンパイル時に `int` と分かる**。型を間違えようがない。
- プロバイダはツリー上の位置に依存しない。`ProviderNotFoundException` 的な「置き場所ミス」が消える。
- `BuildContext` 不要（`ref` で完結）→ ロジックを Widget の外に出しやすい。

---

## ▶️ 動作確認 + Riverpod の「便利さ」を1つ足す

派生した値（カウントの2倍）を、**別プロバイダを1行**で作って合成できます。

```dart
final doubledProvider = Provider<int>((ref) => ref.watch(counterProvider) * 2);
```

`CounterPage` の body に追加:

```dart
Text('doubled = ${ref.watch(doubledProvider)}'),
```

```bash
fvm flutter run -d chrome
```

**観察ポイント:** + を押すと `count` と `doubled` が連動して更新される。
`doubledProvider` は `counterProvider` を `watch` しているだけで、**依存が自動で繋がる**。
素の Provider で同じことをやると `ProxyProvider` 等の追加配線が要ります。

### おまけ：テストでの差し替えが一行
```dart
ProviderScope(
  overrides: [counterProvider.overrideWith(() => FakeCounter())],
  child: ...,
)
```
本番コードを触らずに、テストやプレビューで中身を入れ替えられます。

---

## 🧠 まとめ

| | setState | 素の Provider | Riverpod |
|---|---|---|---|
| 画面をまたぐ共有 | ✕（持ち上げ地獄） | ○ | ○ |
| 型安全な取得 | — | △（`<Foo>` を間違えても通る） | ○（推論される） |
| 置き場所ミス | — | ✕（実行時に `ProviderNotFoundException`） | ○（位置非依存） |
| 値の合成・派生 | 手書き | ProxyProvider 等 | `ref.watch` するだけ |
| テスト差し替え | しにくい | やや手間 | `overrideWith` 一行 |

---

## 落とし穴 / 次の一歩
- `ref.watch` は build 内で（再描画したい依存）。`ref.read` はイベント時に1回だけ（onPressed 等）。使い分け注意。
- 非同期は `FutureProvider` / `AsyncNotifier` と `AsyncValue`（`switch` でローディング/エラー/データを分岐）。
- 規模が出てきたら `@riverpod` アノテーション + `riverpod_generator`（build_runner）で `counterProvider` を**自動生成**できます。書き味は同じで、生成物が `*.g.dart` に出ます。コード生成は次章 freezed で体験します。

# 06. ルーティング — Navigator 1.0 → go_router（URL・ディープリンク・認証ガード）

## 🎯 ゴール
画面遷移を、まず素の `Navigator.push` で書いて限界を知り、go_router の
URL ベース・ディープリンク・redirect ガードに置き換える。

---

## 🚫 ① これがないと（Navigator 1.0 の限界）

```dart
// 別画面へ
Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostPage(id: '42')));
// 戻る
Navigator.of(context).pop();
```

困りごと:
- 画面に**URL がない**。`/post/42` のようなパスで開けない＝ディープリンク（通知やブラウザから直接その画面へ）が作りにくい。
- 「未ログインなら必ずログイン画面へ」のような**横断ガード**を、各画面で手書きする羽目になる。
- 遷移ロジックが `context` に依存して、あちこちに散らばる。

---

## ✅ ② go_router に置き換える

```bash
fvm flutter pub add go_router
```

`lib/main.dart`（まるごと貼り付けて動く最小例）:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 超簡易の「ログイン状態」。実際は Riverpod / supabase の状態に置き換える。
class Auth {
  static bool loggedIn = false;
}

final router = GoRouter(
  initialLocation: '/',
  // ★ ここが認証ガード。全遷移の前に一度通る。
  redirect: (context, state) {
    final goingToLogin = state.matchedLocation == '/login';
    if (!Auth.loggedIn && !goingToLogin) return '/login'; // 未ログインは弾く
    if (Auth.loggedIn && goingToLogin) return '/';        // ログイン済みなら login は不要
    return null; // それ以外はそのまま
  },
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomePage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    // ★ パスパラメータ（/post/42 の 42 を受け取る）
    GoRoute(
      path: '/post/:id',
      builder: (c, s) => PostPage(id: s.pathParameters['id']!),
    ),
  ],
);

void main() => runApp(MaterialApp.router(routerConfig: router));

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/post/42'), // URL で遷移
                child: const Text('Post 42 を開く'),
              ),
              ElevatedButton(
                onPressed: () {
                  Auth.loggedIn = false;
                  context.go('/'); // ガードで /login に飛ばされる
                },
                child: const Text('ログアウト'),
              ),
            ],
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Auth.loggedIn = true;
              context.go('/'); // ログイン後ホームへ
            },
            child: const Text('ログインする'),
          ),
        ),
      );
}

class PostPage extends StatelessWidget {
  const PostPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Post $id')),
        body: Center(child: Text('投稿 #$id の詳細')),
      );
}
```

---

## ▶️ ③ 動作確認

```bash
fvm flutter run -d chrome
```

確認1（**ガード**）: アプリは最初 `/` に行こうとするが、未ログインなので**自動で `/login`** に飛ぶ。
「ログインする」を押すとホームへ。各画面に if 文を書いていないのに、横断的に効いています。

確認2（**URL / ディープリンク**）: Chrome のアドレスバーを `http://localhost:xxxxx/#/post/42`
に手で書き換えて Enter。`Post 42` 画面が直接開く（= 通知やブラウザからその画面に飛べる、の最小形）。

> 補足: web ではデフォルトで `/#/post/42` のハッシュ形式。`#` を消したい場合は
> `usePathUrlStrategy()` を `main` の先頭で呼びます（今回は確認用なのでそのままでOK）。

確認3: 「Post 42 を開く」ボタン → `context.go('/post/42')` で同じ画面へ（コードからの遷移）。

---

## 🧠 まとめ

| | Navigator 1.0 | go_router |
|---|---|---|
| URL | 無い | `/post/:id` で表現 |
| ディープリンク | 作りにくい | パスで直接開ける |
| 認証ガード | 各画面で手書き | `redirect` 一箇所 |
| 遷移の宣言 | 命令的に散在 | routes に集約 |

---

## 落とし穴
- `context.go()` は「置き換え」、`context.push()` は「積む（戻れる）」。用途で使い分け。
- `redirect` は遷移のたびに走る。重い処理や無限ループ（常に別パスを返す等）に注意。
- 実アプリの `Auth.loggedIn` は、Riverpod のプロバイダや supabase のセッションに置き換え、
  `refreshListenable` でログイン状態の変化を router に通知します。

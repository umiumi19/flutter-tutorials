# 09. Supabase 連携 — 自前バックエンド → supabase_flutter（認証・ストレージ）

> この章は無料の Supabase プロジェクト（外部アカウント）が必要です。
> 「認証とファイル保存を自前で作らずに済む」ことを最小で体験します。

## 🎯 ゴール
supabase_flutter で「メールサインアップ → ログイン状態の取得 → ファイルをストレージへアップロード」
までを最小確認する。

---

## 🚫 ① これがないと（自前実装の重さ）

認証を自分で作ると、ざっと:
- ユーザーテーブル、パスワードのハッシュ化、トークン発行・検証、リフレッシュ、
  メール確認、パスワードリセット… を**サーバー側で全部**実装・運用。
- ファイル保存も、アップロード先・URL 発行・権限制御を自前で。

学習や小規模では、ここに時間を取られて本題（アプリの価値）に進めません。

---

## ✅ ② Supabase をつなぐ

### 準備（ブラウザ作業）
1. https://supabase.com で無料プロジェクトを作成。
2. プロジェクトの Settings → API から **Project URL** と **anon public key** を控える。
3. Storage で公開バケット（例: `avatars`）を1つ作る。

### 導入
```bash
fvm flutter pub add supabase_flutter
```

URL とキーは 02 章の `--dart-define` で渡します（コードに直書きしない）。

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MaterialApp(home: AuthDemoPage()));
}

final supabase = Supabase.instance.client;
```

---

## ▶️ ③ 動作確認

最小の「サインアップ → 状態表示 → アップロード」画面:

```dart
class AuthDemoPage extends StatefulWidget {
  const AuthDemoPage({super.key});
  @override
  State<AuthDemoPage> createState() => _AuthDemoPageState();
}

class _AuthDemoPageState extends State<AuthDemoPage> {
  String _status = '未ログイン';

  Future<void> _signUp() async {
    final res = await supabase.auth.signUp(
      email: 'test+${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'password123',
    );
    setState(() => _status = 'userId = ${res.user?.id ?? "(確認メール待ち)"}');
  }

  Future<void> _upload() async {
    final bytes = List<int>.generate(8, (i) => i); // ダミー8バイト
    final path = 'demo/hello.bin';
    await supabase.storage.from('avatars').uploadBinary(
          path,
          // ignore: prefer_const_constructors
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    setState(() => _status = 'uploaded: $url');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status),
            ElevatedButton(onPressed: _signUp, child: const Text('サインアップ')),
            ElevatedButton(onPressed: _upload, child: const Text('ファイルをアップロード')),
          ],
        ),
      ),
    );
  }
}
```

`Uint8List` のため先頭に `import 'dart:typed_data';` を足してください。

```bash
fvm flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

**観察ポイント:**
- 「サインアップ」→ Supabase のダッシュボード Authentication → Users に新規ユーザーが増える
  （メール確認を有効にしている場合は確認待ち表示）。
- 「ファイルをアップロード」→ Storage の `avatars/demo/hello.bin` が増え、`getPublicUrl` の
  URL をブラウザで開ける。
- 自前のサーバーコードはゼロ。認証もストレージも SDK 呼び出しだけで動いた。

---

## 🧠 まとめ

| | 自前バックエンド | supabase_flutter |
|---|---|---|
| 認証 | 全部実装・運用 | `auth.signUp/signIn` |
| ストレージ | 自前で構築 | `storage.from(..).upload` |
| 初速 | 遅い | 速い |
| 学習コスト | 高い | SDK だけ |

ログイン状態は `supabase.auth.onAuthStateChange`（Stream）で監視でき、
06 章の go_router の `redirect` と組み合わせると「未ログインなら /login」が自然に作れます。

---

## 落とし穴
- anon key は公開鍵だが、URL/キーは `--dart-define` で渡しコードに直書きしない。
- 行レベルセキュリティ（RLS）を有効にしないと、本番でデータが筒抜けになり得る。学習後に必ず確認。
- メール確認を有効にしていると `signUp` 直後は `user` が null（確認メール待ち）になることがある。

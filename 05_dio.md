# 05. 通信 — http の手作業 → dio インターセプタで JWT 自動付与

## 🎯 ゴール
全リクエストに認証トークン（JWT）を付ける処理を、まず手で書いてつらさを知り、
dio のインターセプタで**一箇所に集約**する。

---

## 🚫 ① これがないと（毎回ヘッダを手で付ける）

標準の `http` でやると、リクエストごとに `headers` を書きます。

```bash
fvm flutter pub add http
```

```dart
import 'package:http/http.dart' as http;

const token = 'test-token';

Future<void> getProfile() async {
  await http.get(
    Uri.parse('https://httpbin.org/headers'),
    headers: {'Authorization': 'Bearer $token'}, // 毎回書く
  );
}

Future<void> getPosts() async {
  await http.get(
    Uri.parse('https://httpbin.org/headers'),
    headers: {'Authorization': 'Bearer $token'}, // また書く…
  );
}
```

つらい点:
- 新しい API 呼び出しを足すたびに `Authorization` を**書き忘れる**リスク。
- トークンを更新（リフレッシュ）したくなったら、全呼び出し箇所に手が入る。
- 401 が来たときの共通処理（再ログイン誘導など）を一元化できない。

---

## ✅ ② dio のインターセプタで自動付与

```bash
fvm flutter pub add dio
```

```dart
import 'package:dio/dio.dart';

Dio buildDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // ここ一箇所で全リクエストにトークンを付ける
        options.headers['Authorization'] = 'Bearer test-token';
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // 401 の共通処理もここに集約できる（今回はログだけ）
          // ignore: avoid_print
          print('401: トークン切れ。再ログインへ誘導するならここ');
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}
```

各 API 呼び出しは**ヘッダを書かなくてよくなる**:

```dart
Future<void> getProfile(Dio dio) => dio.get('/headers');
Future<void> getPosts(Dio dio) => dio.get('/headers');
```

---

## ▶️ ③ 動作確認

`https://httpbin.org/headers` は、**受け取ったリクエストヘッダをそのまま JSON で返す**便利なエコーAPIです。
インターセプタが効いていれば、返ってきた JSON の中に `Authorization` が見えるはず。

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() async {
  final dio = buildDio();
  final res = await dio.get('/headers');
  debugPrint(res.data.toString()); // ← ここに "Authorization": "Bearer test-token" が含まれる

  runApp(MaterialApp(
    home: Scaffold(body: Center(child: Text(res.data['headers']['Authorization'] ?? 'なし'))),
  ));
}
```

```bash
fvm flutter run -d chrome
```

**観察ポイント:** 画面（とコンソール）に `Bearer test-token` が出る。
各呼び出しではヘッダを一切書いていないのに、サーバー側に届いています。

---

## 🧠 まとめ

| | http 手作業 | dio インターセプタ |
|---|---|---|
| トークン付与 | 呼び出しごとに記述 | 一箇所で全件自動 |
| 付け忘れ | 起きる | 起きない |
| トークン更新 | 全箇所修正 | インターセプタだけ |
| 401 等の共通処理 | バラバラ | 集約できる |

---

## 落とし穴
- `onRequest` では必ず `handler.next(options)`（または `handler.reject`）を呼ぶ。呼ばないとリクエストが止まる。
- 実アプリではトークンは固定文字列でなく、後の章の secure storage から読み出して入れます。
- リフレッシュ（401 → トークン再取得 → リトライ）は同時多発に注意。まずは「付与」と「401 検知」だけ理解すれば十分。

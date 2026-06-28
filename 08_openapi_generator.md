# 08. API クライアント — 手書き → openapi-generator（dart-dio）で生成

> この章はツール（openapi-generator）の導入が必要で、他章より少し重めです。
> 「仕様から型安全なクライアントを生成する」流れを最小で体験するのが目的。

## 🎯 ゴール
OpenAPI 仕様（YAML）から、dio ベースの API クライアント + モデルを**自動生成**して呼び出す。

---

## 🚫 ① これがないと（手書きクライアントは仕様とズレる）

バックエンド（例: Huma）が `/todos` を返すとして、手書きすると:

```dart
// モデルも呼び出しも手書き。サーバーが項目を増やしたら、ここを手で追従…
class Todo {
  final int id; final String title; final bool done;
  Todo({required this.id, required this.title, required this.done});
  factory Todo.fromJson(Map<String, dynamic> j) =>
      Todo(id: j['id'], title: j['title'], done: j['done'] ?? false);
}

Future<List<Todo>> fetchTodos(Dio dio) async {
  final res = await dio.get('/todos');
  return (res.data as List).map((e) => Todo.fromJson(e)).toList();
}
```

問題点:
- サーバーの仕様変更（フィールド追加・型変更）に**手で追従**。追従漏れ＝実行時バグ。
- パスやクエリのタイプミスがコンパイルで止まらない。
- フロントとバックの「真実」が二重管理になる。

---

## ✅ ② 仕様から生成する

### ツール導入（どれか）
```bash
# npm 経由が手軽
npm install -g @openapitools/openapi-generator-cli
# または: brew install openapi-generator
```

### 最小の仕様 `openapi.yaml`
```yaml
openapi: 3.0.3
info: { title: Todo API, version: 1.0.0 }
servers: [{ url: https://example.com }]
paths:
  /todos:
    get:
      operationId: listTodos
      responses:
        '200':
          description: ok
          content:
            application/json:
              schema:
                type: array
                items: { $ref: '#/components/schemas/Todo' }
components:
  schemas:
    Todo:
      type: object
      required: [id, title]
      properties:
        id: { type: integer }
        title: { type: string }
        done: { type: boolean }
```

### 生成
```bash
openapi-generator-cli generate \
  -i openapi.yaml \
  -g dart-dio \
  -o packages/api \
  --additional-properties=pubName=api
```

`packages/api/` に dio ベースのクライアント + モデルが生成されます。
dart-dio は built_value を使うので、生成パッケージ内でさらに build_runner を回します:

```bash
cd packages/api
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
cd ../..
```

アプリ側の `pubspec.yaml` にパス依存を追加:
```yaml
dependencies:
  api:
    path: packages/api
```
```bash
fvm flutter pub get
```

---

## ▶️ ③ 動作確認（コンパイルが通ることを確認）

生成されたクライアントは、こう呼べます（API 名やクラス名は生成物に合わせて補完される）:

```dart
import 'package:api/api.dart';

Future<void> main() async {
  final client = Api(); // 生成された Dio ラッパ
  // 生成された型安全な呼び出し（operationId: listTodos に対応）
  final res = await client.getDefaultApi().listTodos();
  // res.data は BuiltList<Todo>。Todo.id / .title / .done に型付きでアクセスできる
  // ignore: avoid_print
  print(res.data);
}
```

**観察ポイント:**
- `Todo` を手書きしていないのに、`.id` `.title` `.done` に**型付き**でアクセスできる。
- `openapi.yaml` の `Todo` に項目を足して**再生成**すると、Dart 側のモデルが自動で追従する。
  （実サーバーに繋がっていなくても、ここまで＝「生成 → 型付きで呼べる」が確認できればOK）

---

## 🧠 まとめ

| | 手書きクライアント | openapi-generator |
|---|---|---|
| モデル/呼び出し | 手で書く | 仕様から生成 |
| 仕様変更への追従 | 手作業・漏れる | 再生成で自動 |
| 真実の所在 | フロントにも複製 | OpenAPI 仕様が単一の真実 |
| 型安全 | 弱い | 強い |

Huma のようにサーバーが OpenAPI を出力するなら、その YAML を入力にすれば
**バックエンドと常に同期したクライアント**が手に入ります。

---

## 落とし穴
- 生成物（`packages/api`）はコミットするか、CI で必ず再生成する。
- dart-dio は built_value のため、生成後の build_runner を忘れずに。
- ジェネレータのバージョンで出力クラス名が変わることがある。`client.getDefaultApi()` 等は
  生成された `lib/api.dart` を開いて実際の API クラス名を確認してください。

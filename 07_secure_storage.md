# 07. トークン保存 — SharedPreferences → flutter_secure_storage

## 🎯 ゴール
トークンの保存先を、まず SharedPreferences で作って「平文で読める」ことを知り、
flutter_secure_storage（Keychain / Keystore）に置き換える。

---

## 🚫 ① これがないと（SharedPreferences は平文）

```bash
fvm flutter pub add shared_preferences
```

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTokenInsecure(String token) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('token', token);
}

Future<String?> readTokenInsecure() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}
```

問題点:
- SharedPreferences は内部的に **平文ファイル**（Android: `shared_prefs/*.xml`、iOS: `NSUserDefaults` の plist）。
- 端末が root / 脱獄されていたり、バックアップを覗かれると、**トークンがそのまま読める**。
- 「ちょっとした設定値」には最適だが、**認証トークンのような機微情報には不向き**。

（Android エミュレータなら、保存後に
`adb shell run-as <applicationId> cat /data/data/<applicationId>/shared_prefs/*.xml`
で平文の token が見えてしまうことを確認できます。）

---

## ✅ ② flutter_secure_storage に置き換える

OS のセキュア領域（iOS=Keychain / Android=Keystore で暗号化）に保存します。

```bash
fvm flutter pub add flutter_secure_storage
```

> Android はネイティブ設定が必要な場合あり: `android/app/build.gradle` の `minSdkVersion` を
> 18 以上に（最近のテンプレートは満たしています）。

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

Future<void> saveTokenSecure(String token) =>
    _storage.write(key: 'token', value: token);

Future<String?> readTokenSecure() => _storage.read(key: 'token');

Future<void> clearToken() => _storage.delete(key: 'token');
```

API はほぼ同じ感覚（write/read/delete）。違いは**保存先が暗号化された領域**であること。

---

## ▶️ ③ 動作確認

iOS シミュレータ or Android エミュレータで実行（secure storage は web では擬似動作なので**実機/エミュ推奨**）。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

void main() => runApp(const MaterialApp(home: TokenPage()));

class TokenPage extends StatefulWidget {
  const TokenPage({super.key});
  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  String _read = '(未読込)';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Storage')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('読み出し: $_read'),
            ElevatedButton(
              onPressed: () => storage.write(key: 'token', value: 'secret-jwt-123'),
              child: const Text('保存する'),
            ),
            ElevatedButton(
              onPressed: () async {
                final v = await storage.read(key: 'token');
                setState(() => _read = v ?? '(なし)');
              },
              child: const Text('読み出す'),
            ),
          ],
        ),
      ),
    );
  }
}
```

```bash
fvm flutter run   # 接続中のエミュ/実機へ
```

**観察ポイント:**
- 「保存する」→「読み出す」で `secret-jwt-123` が表示される（暗号化領域から復号して取得）。
- アプリを再起動しても残っている（永続化）。
- SharedPreferences と違い、ファイルを直接覗いても平文では出てこない。

---

## 🧠 まとめ

| | SharedPreferences | flutter_secure_storage |
|---|---|---|
| 保存先 | 平文ファイル | Keychain / Keystore（暗号化） |
| 機微情報 | 不向き | 向く（JWT・リフレッシュトークン） |
| 用途 | 設定値・フラグ | 認証トークンなど秘密 |
| 速度・手軽さ | 速い・軽い | 少し重い（暗号処理） |

使い分けの原則: **秘密 → secure_storage、それ以外の設定 → SharedPreferences**。

---

## 落とし穴
- web では暗号化の担保が弱い（実体はブラウザ保存）。機微情報を web で扱うなら設計を見直す。
- 大量データの保存先ではない（小さなキー/値向け）。
- 05 章の dio インターセプタと組み合わせ、`onRequest` で `readTokenSecure()` の値を入れるのが実戦の形。

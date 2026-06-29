import 'package:flutter/material.dart';
import 'features/02_dart_define/page.dart';
import 'features/placeholder_page.dart';

void main() => runApp(const MaterialApp(home: HomePage()));

class _Tutorial {
  const _Tutorial({
    required this.title,
    required this.page,
    this.hasDemo = true,
  });
  final String title;
  final Widget page;
  final bool hasDemo;
}

final _tutorials = [
  _Tutorial(
    title: '01. FVM によるバージョン管理',
    page: const PlaceholderPage(title: '01. FVM'),
    hasDemo: false,
  ),
  _Tutorial(title: '02. dart-define で環境設定を切り替える', page: const DartDefinePage()),
  _Tutorial(
    title: '03. Riverpod による状態管理',
    page: const PlaceholderPage(title: '03. Riverpod'),
  ),
  _Tutorial(
    title: '04. Freezed + JSON シリアライズ',
    page: const PlaceholderPage(title: '04. Freezed + JSON'),
  ),
  _Tutorial(
    title: '05. Dio による HTTP 通信',
    page: const PlaceholderPage(title: '05. Dio'),
  ),
  _Tutorial(
    title: '06. go_router によるルーティング',
    page: const PlaceholderPage(title: '06. go_router'),
  ),
  _Tutorial(
    title: '07. flutter_secure_storage',
    page: const PlaceholderPage(title: '07. SecureStorage'),
  ),
  _Tutorial(
    title: '08. OpenAPI Generator',
    page: const PlaceholderPage(title: '08. OpenAPI Generator'),
  ),
  _Tutorial(
    title: '09. Supabase 連携',
    page: const PlaceholderPage(title: '09. Supabase'),
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter チュートリアル')),
      body: ListView.separated(
        itemCount: _tutorials.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = _tutorials[i];
          return ListTile(
            title: Text(t.title),
            trailing: t.hasDemo
                ? const Icon(Icons.arrow_forward_ios, size: 14)
                : const Text(
                    'コマンドのみ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
            onTap: t.hasDemo
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => t.page),
                  )
                : null,
          );
        },
      ),
    );
  }
}

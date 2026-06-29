import 'package:flutter/material.dart';
import 'set_state_page.dart';
import 'provider_page.dart';
import 'riverpod_page.dart';

class RiverpodMenuPage extends StatelessWidget {
  const RiverpodMenuPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('03. 状態管理')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('① setState'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SetStatePage()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('② 素の Provider'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderPage()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('③ Riverpod'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiverpodPage()),
            ),
          ),
        ],
      ),
    );
  }
}

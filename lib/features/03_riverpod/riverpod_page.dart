import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final counterProvider = NotifierProvider<Counter, int>(Counter.new);

class Counter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final doubledProvider = Provider<int>((ref) {
  final count = ref.watch(counterProvider);
  return count * 2;
});

class RiverpodPage extends ConsumerWidget {
  const RiverpodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final doubled = ref.watch(doubledProvider);
    return Scaffold(
      appBar: AppBar(title: Text('③ Riverpod count = $count')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('doubled = $doubled', style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

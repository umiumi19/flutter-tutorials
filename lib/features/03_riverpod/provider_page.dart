import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CounterModel extends ChangeNotifier {
  int count = 0;
  void increment() {
    count++;
    notifyListeners(); // 「値が変わったから再描画してください」と通知する
  }
}

class ProviderPage extends StatelessWidget {
  const ProviderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const _CounterView(),
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterModel>().count;
    return Scaffold(
      appBar: AppBar(title: Text('② Provider count = $count')),
      body: Center(child: Text('$count', style: const TextStyle(fontSize: 48))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterModel>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

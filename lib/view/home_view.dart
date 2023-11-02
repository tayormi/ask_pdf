import 'package:ask_pdf/view/notifiers/index_notifier.dart';
import 'package:ask_pdf/view/notifiers/query_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _formKey = GlobalKey<FormState>();

class HomeView extends HookConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryState = ref.watch(queryNotifierProvider);
    final queryTextCtrl = useTextEditingController();
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ask a question'),
              TextField(
                controller: queryTextCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter a query',
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    ref
                        .read(queryNotifierProvider.notifier)
                        .queryPineConeIndex(queryTextCtrl.text);
                  },
                  child: const Text('Ask'),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                  onPressed: () {
                    ref
                        .read(indexNotifierProvider.notifier)
                        .createAndUploadPineConeIndex();
                  },
                  child: const Text('Upload PDF')),
              const SizedBox(height: 20),
              if (queryState.state == QueryEnum.loading)
                const LinearProgressIndicator(),
              if (queryState.state == QueryEnum.loaded)
                Align(
                  alignment: Alignment.center,
                  child: Text(queryState.result),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}

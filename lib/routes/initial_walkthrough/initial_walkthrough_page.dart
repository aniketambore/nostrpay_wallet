import 'package:flutter/material.dart';

class InitialWalkthroughPage extends StatefulWidget {
  const InitialWalkthroughPage({super.key});

  @override
  State<InitialWalkthroughPage> createState() => _InitialWalkthroughPageState();
}

class _InitialWalkthroughPageState extends State<InitialWalkthroughPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _createWallet(),
                child: Text('Create Wallet'),
              ),
              ElevatedButton(
                onPressed: () => _restoreNodeFromMnemonicSeed(),
                child: Text('Restore Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createWallet({String? mnemonic}) async {}

  void _restoreNodeFromMnemonicSeed({
    List<String>? initialWords,
  }) async {
    debugPrint("Restore node from mnemonic seed");
  }
}

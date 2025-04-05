import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:nostrpay_wallet/component_library/component_library.dart';

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

  Future<void> _createWallet({String? mnemonic}) async {
    final isRestore = mnemonic != null;
    debugPrint("${isRestore ? "Restore" : "Starting new"} node");
    final accountCubit = context.read<AccountCubit>();
    final navigator = Navigator.of(context);
    var loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);

    try {
      // final seedPhrase = mnemonic ?? (await Mnemonic.generate()).seedPhrase;
      final seedPhrase = mnemonic ?? bip39.generateMnemonic(strength: 128);
      debugPrint('Restore: $isRestore, Seed: $seedPhrase');
      await accountCubit.connect(
        mnemonic: seedPhrase,
        isRestore: isRestore,
      );
      navigator.pushReplacementNamed('/');
    } catch (error, stackTrace) {
      debugPrint(
          "Failed to ${isRestore ? "restore" : "register"} node. Error: $error");
      if (isRestore) {
        _restoreNodeFromMnemonicSeed(initialWords: mnemonic.split(" "));
      }
      if (!mounted) return;
      final errorMessage = 'Error: $error\nStackTrace: $stackTrace';
      debugPrint(errorMessage);
      context.showErrorPrompt(errorMessage);
    } finally {
      navigator.removeRoute(loaderRoute);
    }
  }

  void _restoreNodeFromMnemonicSeed({
    List<String>? initialWords,
  }) async {
    debugPrint("Restore node from mnemonic seed");
  }
}

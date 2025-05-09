import 'package:flutter/foundation.dart';
import 'package:nostrpay_wallet/services/keychain.dart';

class CredentialsManager {
  static const String accountMnemonic = "account_mnemonic";

  final KeyChain keyChain;

  CredentialsManager({required this.keyChain});

  Future storeMnemonic({
    required String mnemonic,
  }) async {
    try {
      await _storeMnemonic(mnemonic);
      debugPrint("Stored credentials successfully");
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<String> restoreMnemonic() async {
    try {
      String? mnemonicStr = await keyChain.read(accountMnemonic);
      debugPrint("Restored credentials successfully");
      return mnemonicStr!;
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<void> removeMnemonic() async {
    await keyChain.delete(accountMnemonic);
  }

  // Helper methods
  Future<void> _storeMnemonic(String mnemonic) async {
    await keyChain.write(accountMnemonic, mnemonic);
  }
}

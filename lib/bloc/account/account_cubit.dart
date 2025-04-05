import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ldk_node/ldk_node.dart';
import 'package:nostrpay_wallet/config.dart' as cfg;

import 'account_state.dart';
import 'credentials_manager.dart';

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  Node? _ldkNode;
  final CredentialsManager _credentialsManager;

  AccountCubit(
    this._credentialsManager,
  ) : super(AccountState.initial()) {
    hydrate();

    if (!state.initial) connect();
  }

  Future connect({
    String? mnemonic,
    bool isRestore = true,
  }) async {
    debugPrint(
        "connect new mnemonic: ${mnemonic != null}, restored: $isRestore");
    emit(state.copyWith(connectionStatus: ConnectionStatus.CONNECTING));

    if (mnemonic != null) {
      await _credentialsManager.storeMnemonic(mnemonic: mnemonic);
      emit(state.copyWith(initial: false));
    }

    await _startSdkForever(isRestore: isRestore);
  }

  Future _startSdkForever({bool isRestore = true}) async {
    debugPrint("starting sdk forever");
    await _startSdkOnce(isRestore: isRestore);

    // in case we failed to start (lack of inet connection probably)
    if (state.connectionStatus == ConnectionStatus.DISCONNECTED) {
      StreamSubscription<List<ConnectivityResult>>? subscription;
      subscription = Connectivity().onConnectivityChanged.listen((event) async {
        // we should try fetch the selected lsp information when internet is back.
        if (event.contains(ConnectivityResult.none) &&
            state.connectionStatus == ConnectionStatus.DISCONNECTED) {
          await _startSdkOnce();
          if (state.connectionStatus == ConnectionStatus.CONNECTED) {
            subscription!.cancel();
            _onConnected();
          }
        }
      });
    } else {
      _onConnected();
    }
  }

  Future _startSdkOnce({bool isRestore = true}) async {
    debugPrint("starting sdk once");
    var config = await cfg.Config.instance();
    try {
      emit(state.copyWith(connectionStatus: ConnectionStatus.CONNECTING));
      final mnemonic = await _credentialsManager.restoreMnemonic();
      debugPrint('mnemonic: $mnemonic');
      final builder = config.nodeConfig
          .setEntropyBip39Mnemonic(mnemonic: Mnemonic(seedPhrase: mnemonic));
      _ldkNode = await builder.build();
      await _ldkNode!.start();

      // TODO: Fetch node details after successful start
    } catch (e) {
      debugPrint("failed to connect to ldk_node lib $e");
      emit(state.copyWith(connectionStatus: ConnectionStatus.DISCONNECTED));
      rethrow;
    }
  }

  // Once connected sync sdk periodically on foreground events.
  void _onConnected() async {
    debugPrint("on connected");
    await _ldkNode?.syncWallets();
    // TODO: sync sdk periodically
  }

  @override
  AccountState? fromJson(Map<String, dynamic> json) {
    return AccountState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AccountState state) {
    return state.toJson();
  }
}

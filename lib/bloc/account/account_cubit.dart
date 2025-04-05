import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ldk_node/ldk_node.dart';
import 'package:nostrpay_wallet/app_config.dart';
import 'package:nostrpay_wallet/config.dart' as cfg;
import 'package:nostrpay_wallet/models/models.dart';
import 'package:nostrpay_wallet/services/olympus_api.dart';

import 'account_state.dart';
import 'credentials_manager.dart';

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  Node? _ldkNode;
  final CredentialsManager _credentialsManager;

  AccountCubit(
    this._credentialsManager,
  )   : _olympusApi = OlympusApi(),
        super(AccountState.initial()) {
    hydrate();

    if (!state.initial) connect();
  }

  final OlympusApi _olympusApi;

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

      // Fetch node details after successful start
      await fetchNodeDetails();
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

  Future<void> fetchNodeDetails() async {
    debugPrint("Fetching node details...");
    final nodeId = await getNodeId();
    final balanceSat = await getSpendableBalanceSat();
    final inboundLiquiditySat = await getInboundLiquiditySat();

    debugPrint("NodeId: $nodeId");

    emit(state.copyWith(
      id: nodeId,
      balanceSat: balanceSat,
      maxInboundLiquiditySat: inboundLiquiditySat,
    ));
  }

  Future<String?> getNodeId() async {
    if (_ldkNode != null) {
      debugPrint('Getting node id');
      final nodeId = await _ldkNode!.nodeId();
      return nodeId.hex;
    }
    return null;
  }

  Future<int?> getSpendableBalanceSat() async {
    if (_ldkNode != null) {
      debugPrint('Getting spendable balance');

      final usableChannels =
          (await _ldkNode!.listChannels()).where((channel) => channel.isUsable);

      final outboundCapacityMsat = usableChannels.fold(
        BigInt.zero,
        (sum, channel) => sum + channel.outboundCapacityMsat,
      );

      final balanceSat = (outboundCapacityMsat ~/ BigInt.from(1000)).toInt();

      return balanceSat;
    }
    return null;
  }

  Future<int> getInboundLiquiditySat() async {
    if (_ldkNode != null) {
      debugPrint("Getting inbound liquidity");
      // Get the total inbound liquidity in satoshis by summing up the inbound
      // capacity of all channels that are usable and return it in satoshis.
      final usableChannels =
          (await _ldkNode!.listChannels()).where((channel) => channel.isUsable);

      final inboundCapacityMsat = usableChannels.fold(
        BigInt.zero,
        (sum, channel) => sum + channel.inboundCapacityMsat,
      );

      final inboundLiquiditySat =
          (inboundCapacityMsat ~/ BigInt.from(1000)).toInt();

      return inboundLiquiditySat;
    }
    return 0;
  }

  Future<List<String>> listChannels() async {
    final channels = await _ldkNode!.listChannels();
    List<String> channelInfo = [];

    for (final ChannelDetails channel in channels) {
      final outboundCapacitySat =
          (channel.outboundCapacityMsat ~/ BigInt.from(1000)).toInt();
      final inboundCapacitySat =
          (channel.inboundCapacityMsat ~/ BigInt.from(1000)).toInt();

      channelInfo
          .add('Channel Status: ${channel.isUsable ? 'Usable' : 'Not Usable'}');
      channelInfo.add('Channel ID: ${channel.counterpartyNodeId.hex}');
      channelInfo.add('Channel Value: ${channel.channelValueSats} sats');
      channelInfo.add('Outbound Capacity: $outboundCapacitySat sats');
      channelInfo.add('Inbound Capacity: $inboundCapacitySat sats');
    }

    return channelInfo;
  }

  Future<String> addInvoice({
    String description = "",
    required int amountSat,
    int expirySecs = 3600 * 24, // Default to 1 day
  }) async {
    debugPrint("addInvoice: $description, $amountSat");

    Bolt11Payment bolt11Payment = await _ldkNode!.bolt11Payment();

    Bolt11Invoice req = await bolt11Payment.receive(
      amountMsat: BigInt.from(amountSat * 1000),
      expirySecs: expirySecs,
      description: description,
    );
    return req.signedRawInvoice;
  }

  Future<bool> _connectToOlympus() async {
    if (_ldkNode != null) {
      debugPrint('Connecting to Olympus');
      final appConfig = AppConfig();
      await _ldkNode!.connect(
        address: appConfig.lsps1.olympusSignet.address,
        nodeId: appConfig.lsps1.olympusSignet.nodeId,
        persist: true,
      );
      return true;
    }
    return false;
  }

  Future<bool> connectToOlympusWithRetry({
    Duration retryDelay = const Duration(seconds: 3),
    int maxRetries = 10,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      final isConnected = await _connectToOlympus();
      if (isConnected) {
        debugPrint("Successfully connected to Olympus");
        return true;
      }

      debugPrint("Retrying connection to Olympus...");
      retryCount++;

      // Wait for the specified delay before the next retry
      await Future.delayed(retryDelay);
    }

    debugPrint("Failed to connect to Olympus after $maxRetries attempts");
    return false;
  }

  Future<OlympusFeeResponseRM> getLSPFee({required int amountSat}) async {
    final pubkey = state.id!;
    final amountMSat = satToMsat(amountSat);
    final res =
        await _olympusApi.getLSPFee(amountMSat: amountMSat, pubkey: pubkey);
    return res;
  }

  Future<OlympusProposalResponseRM> getProposal({
    required String bolt11,
    required String feeId,
  }) async {
    final res = await _olympusApi.getProposal(bolt11: bolt11, feeId: feeId);
    return res;
  }

  int satToMsat(int satoshis) {
    return satoshis * 1000;
  }

  int mSatToSat(int millisatoshis) {
    return millisatoshis ~/ 1000;
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

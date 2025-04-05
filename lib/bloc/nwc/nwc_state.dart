import 'dart:convert';

import 'package:nwc_wallet/enums/nwc_method.dart';
import 'package:nwc_wallet/enums/bitcoin_network.dart';

class NWCState {
  final bool isInitialized;
  final String alias;
  final String color;
  final String pubkey;
  final BitcoinNetwork network;
  final int blockHeight;
  final String blockHash;
  final List<NwcMethod> methods;
  final int balanceSat;
  final String connectionUri;
  final String relay;
  final bool? isLoading;
  final String? error;

  const NWCState({
    required this.isInitialized,
    required this.alias,
    required this.color,
    required this.pubkey,
    required this.network,
    required this.blockHeight,
    required this.blockHash,
    required this.methods,
    required this.balanceSat,
    required this.connectionUri,
    required this.relay,
    this.isLoading,
    this.error,
  });

  NWCState.initial()
      : this(
          isInitialized: false,
          alias: 'LDK <> NWC',
          color: '#FF9900',
          pubkey: '',
          network: BitcoinNetwork.signet,
          blockHeight: 0,
          blockHash: '',
          methods: [
            NwcMethod.getInfo,
            NwcMethod.getBalance,
            NwcMethod.makeInvoice,
          ],
          balanceSat: 0,
          connectionUri: '',
          relay: 'wss://nostrue.com',
          isLoading: false,
          error: null,
        );

  NWCState copyWith({
    bool? isInitialized,
    String? alias,
    String? color,
    String? pubkey,
    BitcoinNetwork? network,
    int? blockHeight,
    String? blockHash,
    List<NwcMethod>? methods,
    int? balanceSat,
    String? error,
    String? connectionUri,
    String? relay,
    bool? isLoading,
  }) {
    return NWCState(
      isInitialized: isInitialized ?? this.isInitialized,
      alias: alias ?? this.alias,
      color: color ?? this.color,
      pubkey: pubkey ?? this.pubkey,
      network: network ?? this.network,
      blockHeight: blockHeight ?? this.blockHeight,
      blockHash: blockHash ?? this.blockHash,
      methods: methods ?? this.methods,
      balanceSat: balanceSat ?? this.balanceSat,
      error: error ?? this.error,
      connectionUri: connectionUri ?? this.connectionUri,
      relay: relay ?? this.relay,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isInitialized': isInitialized,
      'alias': alias,
      'color': color,
      'pubkey': pubkey,
      'network': network.name,
      'blockHeight': blockHeight,
      'blockHash': blockHash,
      'methods': methods.map((method) => method.name).toList(),
      'balanceSat': balanceSat,
      'connectionUri': connectionUri,
      'relay': relay,
    };
  }

  factory NWCState.fromJson(Map<String, dynamic> json) {
    return NWCState(
      isInitialized: json['isInitialized'] as bool,
      alias: json['alias'] as String,
      color: json['color'] as String,
      pubkey: json['pubkey'] as String,
      network: BitcoinNetwork.values.byName(json['network'] as String),
      blockHeight: json['blockHeight'] as int,
      blockHash: json['blockHash'] as String,
      methods: (json['methods'] as List)
          .map((method) => NwcMethod.values.byName(method as String))
          .toList(),
      balanceSat: json['balanceSat'] as int,
      connectionUri: json['connectionUri'] as String,
      relay: json['relay'] as String,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

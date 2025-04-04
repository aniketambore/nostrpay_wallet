import 'dart:convert';

enum ConnectionStatus { CONNECTING, CONNECTED, DISCONNECTED }

class AccountState {
  final String? id;
  final bool initial;
  final int balanceSat;
  final int maxInboundLiquiditySat;
  final ConnectionStatus? connectionStatus;

  const AccountState({
    required this.id,
    required this.initial,
    required this.balanceSat,
    required this.maxInboundLiquiditySat,
    required this.connectionStatus,
  });

  AccountState.initial()
      : this(
          id: null,
          initial: true,
          balanceSat: 0,
          maxInboundLiquiditySat: 0,
          connectionStatus: null,
        );

  AccountState copyWith({
    String? id,
    bool? initial,
    int? balanceSat,
    int? maxInboundLiquiditySat,
    ConnectionStatus? connectionStatus,
  }) {
    return AccountState(
      id: id ?? this.id,
      initial: initial ?? this.initial,
      balanceSat: balanceSat ?? this.balanceSat,
      maxInboundLiquiditySat:
          maxInboundLiquiditySat ?? this.maxInboundLiquiditySat,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  Map<String, dynamic>? toJson() {
    return {
      "id": id,
      "initial": initial,
      "balanceSat": balanceSat,
      "maxInboundLiquiditySat": maxInboundLiquiditySat,
      "connectionStatus": connectionStatus?.index,
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      id: json["id"],
      initial: json["initial"],
      balanceSat: json["balanceSat"],
      maxInboundLiquiditySat: json["maxInboundLiquiditySat"] ?? 0,
      connectionStatus: json["connectionStatus"] != null
          ? ConnectionStatus.values[json["connectionStatus"]]
          : ConnectionStatus.CONNECTING,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

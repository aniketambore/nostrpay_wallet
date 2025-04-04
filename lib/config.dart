import 'dart:io';

// import 'package:app_group_directory/app_group_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_group_directory/flutter_app_group_directory.dart';
import 'package:ldk_node/ldk_node.dart' as ldk;
import 'package:nostrpay_wallet/services/injector.dart';
import 'package:path_provider/path_provider.dart';

import 'app_config.dart';

class Config {
  static Config? _instance;

  final String workingDir;
  final String nodePath;
  final ldk.Builder nodeConfig;

  Config._({
    required this.workingDir,
    required this.nodePath,
    required this.nodeConfig,
  });

  static Future<Config> instance({
    ServiceInjector? serviceInjector,
  }) async {
    debugPrint("Getting Config instance");
    if (_instance == null) {
      debugPrint("Creating Config instance");
      // final injector = serviceInjector ?? ServiceInjector();
      final nostrpayConfig = await _getBundledConfig();
      final workingDir = await _workingDir();
      final nodePath = _nodePath(workingDir);
      final nodeConfig = await getNodeConfig(nostrpayConfig, nodePath);

      _instance = Config._(
        workingDir: workingDir,
        nodePath: nodePath,
        nodeConfig: nodeConfig,
      );
    }

    return _instance!;
  }

  static Future<AppConfig> _getBundledConfig() async {
    debugPrint("Getting bundled config");
    return AppConfig();
  }

  static Future<ldk.Builder> getNodeConfig(
    AppConfig nostrpayConfig,
    String nodePath,
  ) async {
    debugPrint("Getting Node config");

    final anchorChannelsConfig = ldk.AnchorChannelsConfig(
      trustedPeersNoReserve: [nostrpayConfig.lsps1.olympusSignet.nodeId],
      perChannelReserveSats: BigInt.from(25000),
    );

    final config = ldk.Config(
      storageDirPath: nodePath,
      network: nostrpayConfig.network.signet,
      defaultCltvExpiryDelta: 144,
      onchainWalletSyncIntervalSecs: BigInt.from(60),
      walletSyncIntervalSecs: BigInt.from(20),
      feeRateCacheUpdateIntervalSecs: BigInt.from(200),
      trustedPeers0Conf: [nostrpayConfig.lsps1.olympusSignet.nodeId],
      probingLiquidityLimitMultiplier: BigInt.from(3),
      logLevel: ldk.LogLevel.trace,
      anchorChannelsConfig: anchorChannelsConfig,
    );

    final builder = ldk.Builder.fromConfig(config: config)
        .setEsploraServer(nostrpayConfig.esploraServerURL.mutinySignet.url)
        .setListeningAddresses(nostrpayConfig.listeningAddresses)
        .setGossipSourceRgs(nostrpayConfig.rgsSource.signet);

    return builder;
  }

  static Future<String> _workingDir() async {
    String path = "";
    if (defaultTargetPlatform == TargetPlatform.android) {
      final workingDir = await getApplicationDocumentsDirectory();
      path = workingDir.path;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final sharedDirectory =
          await FlutterAppGroupDirectory.getAppGroupDirectory(
        "group.${const String.fromEnvironment("APP_ID_PREFIX")}.com.example.nostrpay_wallet",
      );
      if (sharedDirectory == null) {
        throw Exception("Could not get shared directory");
      }
      path = sharedDirectory.path;
    }
    debugPrint("Using workingDir: $path");
    return path;
  }

  static String _nodePath(String workingDir) {
    return "$workingDir/ldk_cache";
  }

  static Future<void> deleteLDKCacheFile() async {
    final workingDir = await _workingDir();
    final nodeDir = _nodePath(workingDir);
    final dir = Directory(nodeDir);

    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
        debugPrint("Successfully deleted directory: $nodeDir");
      } catch (e) {
        debugPrint("Failed to delete directory: $e");
      }
    } else {
      debugPrint("Directory does not exist: $dir");
    }
  }
}

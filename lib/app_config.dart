import 'package:ldk_node/ldk_node.dart';

class AppConfig {
  final EsploraServerURLNetwork network = EsploraServerURLNetwork();
  final EsploraServerURL esploraServerURL = EsploraServerURL();

  final List<SocketAddress> listeningAddresses = [
    const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
  ];

  final LSPS1 lsps1 = const LSPS1();

  final RGSServerURLNetwork rgsSource = const RGSServerURLNetwork();

  static const OlympusLspUrl olympusLspUrl = OlympusLspUrl();
}

class EsploraServerURLNetwork {
  final Network bitcoin = Network.bitcoin;
  final Network testnet = Network.testnet;
  final Network signet = Network.signet;
}

class EsploraServerURL {
  final EsploraServer blockstreamBitcoin = const EsploraServer(
    name: "Blockstream",
    url: "https://blockstream.info/api",
  );

  final EsploraServer mempoolspaceBitcoin = const EsploraServer(
    name: "Mempool",
    url: "https://mempool.space/api",
  );

  final EsploraServer mutinySignet = const EsploraServer(
    name: "Mutiny",
    url: "https://mutinynet.com/api",
  );

  final EsploraServer blockstreamTestnet = const EsploraServer(
    name: "Blockstream",
    url: "http://blockstream.info/testnet/api",
  );

  final EsploraServer mempoolspaceTestnet = const EsploraServer(
    name: "Mempool.space",
    url: "https://mempool.space/testnet/api",
  );
}

class EsploraServer {
  final String name;
  final String url;

  const EsploraServer({required this.name, required this.url});
}

class LSPS1 {
  const LSPS1();

  final LightningServiceProvider olympusSignet = const LightningServiceProvider(
    address: SocketAddress.hostname(addr: "45.79.201.241", port: 9735),
    nodeId: PublicKey(
        hex:
            '032ae843e4d7d177f151d021ac8044b0636ec72b1ce3ffcde5c04748db2517ab03'),
  );

  final LightningServiceProvider olympusTestnet =
      const LightningServiceProvider(
    address: SocketAddress.hostname(addr: "139.144.22.237", port: 9735),
    nodeId: PublicKey(
        hex:
            '03e84a109cd70e57864274932fc87c5e6434c59ebb8e6e7d28532219ba38f7f6df'),
  );

  final LightningServiceProvider olympusMainnet =
      const LightningServiceProvider(
    address: SocketAddress.hostname(addr: "45.79.192.236", port: 9735),
    nodeId: PublicKey(
        hex:
            '031b301307574bbe9b9ac7b79cbe1700e31e544513eae0b5d7497483083f99e581'),
  );
}

class LightningServiceProvider {
  final SocketAddress address;
  final PublicKey nodeId;

  const LightningServiceProvider({
    required this.address,
    required this.nodeId,
  });
}

class RGSServerURLNetwork {
  const RGSServerURLNetwork();

  final String bitcoin = "https://rapidsync.lightningdevkit.org/snapshot/";
  final String testnet =
      "https://rapidsync.lightningdevkit.org/testnet/snapshot/";
  // final String signet = "https://mutinynet.lspd.lqwd.tech";
  final String signet = "https://rgs.mutinynet.com/snapshot/";
}

class OlympusLspUrl {
  const OlympusLspUrl();

  final String mainnet = 'https://0conf.lnolymp.us';
  final String testnet = 'https://testnet-0conf.lnolymp.us';
  final String signet = 'https://mutinynet-flow.lnolymp.us';
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/bloc/account/account_state.dart';
import 'package:nostrpay_wallet/bloc/account/credentials_manager.dart';
import 'package:nostrpay_wallet/bloc/nwc/nwc_cubit.dart';
import 'package:nostrpay_wallet/bloc/nwc/nwc_state.dart';
import 'package:nostrpay_wallet/services/injector.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    _initializeNWC();
  }

  Future<void> _initializeNWC() async {
    final credentialsManager = CredentialsManager(
      keyChain: ServiceInjector().keychain,
    );
    final mnemonic = await credentialsManager.restoreMnemonic();
    if (mnemonic.isNotEmpty) {
      if (mounted) {
        final nwcCubit = context.read<NWCCubit>();
        await nwcCubit.initialize(mnemonic);

        // Only create a connection if one doesn't exist
        if (nwcCubit.state.connectionUri.isEmpty) {
          debugPrint('AccountPage: No existing connection, creating a new one');
          await nwcCubit.createConnection();
        } else {
          debugPrint(
              'AccountPage: Using existing connection: ${nwcCubit.state.connectionUri}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accountState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BalanceCard(accountState: accountState),
              const SizedBox(height: 24),
              _WalletActions(),
              const SizedBox(height: 24),
              _NWCConnectionCard(),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.accountState});
  final AccountState accountState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Balance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${accountState.balanceSat} sats',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inbound Liquidity: ${accountState.maxInboundLiquiditySat} sats',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Node ID: ${accountState.id ?? 'Not connected'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletActions extends StatelessWidget {
  const _WalletActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.send,
          label: 'Send',
          onPressed: () {},
        ),
        _buildActionButton(
          icon: Icons.call_received,
          label: 'Receive',
          onPressed: () {
            Navigator.of(context).pushNamed("/create-invoice");
          },
        ),
        _buildActionButton(
          icon: Icons.visibility,
          label: 'Mnemonic',
          onPressed: () async {
            final credentialsManager = CredentialsManager(
              keyChain: ServiceInjector().keychain,
            );
            final mnemonic = await credentialsManager.restoreMnemonic();

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Wallet Mnemonic'),
                  content: SelectableText(mnemonic),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        _buildActionButton(
          icon: Icons.account_tree,
          label: 'Channels',
          onPressed: () async {
            final cubit = context.read<AccountCubit>();
            final channels = await cubit.listChannels();

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Lightning Channels'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: channels
                          .map((info) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(info),
                              ))
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 32,
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _NWCConnectionCard extends StatelessWidget {
  const _NWCConnectionCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NWCCubit, NWCState>(
      builder: (context, state) {
        debugPrint(
            '_NWCConnectionCard: Building with state - isLoading: ${state.isLoading}, error: ${state.error}');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nostr Wallet Connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isLoading ?? false)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.error ?? 'Unknown error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  )
                else
                  SelectableText(
                    state.connectionUri,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

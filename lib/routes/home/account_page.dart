import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/bloc/account/account_state.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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

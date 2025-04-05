import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';

import 'account_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Pay ⚡️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (context.mounted) {
                await context.read<AccountCubit>().fetchNodeDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Node details fetched successfully'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: AccountPage(),
    );
  }
}

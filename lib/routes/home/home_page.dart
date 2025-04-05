import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/component_library/component_library.dart';

import 'account_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<bool> _connectFuture;

  @override
  void initState() {
    super.initState();
    _connectFuture = _connectToService();
  }

  Future<bool> _connectToService() {
    return context.read<AccountCubit>().connectToOlympusWithRetry();
  }

  void _retryConnection() {
    setState(() {
      _connectFuture = _connectToService();
    });
  }

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
      body: FutureBuilder<bool>(
        future: _connectFuture,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasError) {
            final errorMessage =
                'Error: ${snapshot.error}\nStackTrace: ${snapshot.stackTrace}';
            return ErrorDisplayWidget(
              error: errorMessage,
              onRetry: _retryConnection,
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return const AccountPage();
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/bloc/account/credentials_manager.dart';
import 'package:nostrpay_wallet/bloc/nwc/nwc_cubit.dart';
import 'package:nostrpay_wallet/services/injector.dart';
import 'package:nostrpay_wallet/services/service_locator.dart';
import 'package:path_provider/path_provider.dart';
import 'config.dart' as cfg;
import 'package:path/path.dart' as p;

import 'user_app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );

    final injector = ServiceInjector();

    final appDir = await getApplicationDocumentsDirectory();
    final config = await cfg.Config.instance();

    final storage = await HydratedStorage.build(
      storageDirectory:
          HydratedStorageDirectory(p.join(appDir.path, "bloc_storage")),
    );
    HydratedBloc.storage = storage;

    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountCubit>(
            create: (BuildContext context) {
              final accountCubit = AccountCubit(
                CredentialsManager(keyChain: injector.keychain),
              );
              // Set up the AccountCubit in the service locator
              ServiceLocator().setAccountCubit(accountCubit);
              return accountCubit;
            },
          ),
          BlocProvider<NWCCubit>(
            create: (BuildContext context) => NWCCubit(),
          ),
        ],
        child: UserApp(),
      ),
    );
  }, (error, stackTrace) async {
    if (error is! FlutterErrorDetails) {
      debugPrint("[!] FlutterError: $error and StackTrace: $stackTrace");
    }
  });
}

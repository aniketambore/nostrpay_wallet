import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/bloc/account/account_state.dart';
import 'package:nostrpay_wallet/routes/create_invoice/create_invoice_page.dart';
import 'package:nostrpay_wallet/routes/home/home_page.dart';
import 'package:nostrpay_wallet/routes/initial_walkthrough/initial_walkthrough_page.dart';
import 'package:nostrpay_wallet/routes/splash/splash_page.dart';

class UserApp extends StatelessWidget {
  final GlobalKey _appKey = GlobalKey();
  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();

  UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
        builder: (context, accState) {
      return MaterialApp(
        key: _appKey,
        title: 'Nostrpay',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: 'splash',
        onGenerateRoute: (RouteSettings settings) {
          debugPrint("New route: ${settings.name}");
          switch (settings.name) {
            case 'splash':
              return MaterialPageRoute(
                builder: (_) => SplashPage(isInitial: accState.initial),
                settings: settings,
              );
            case '/intro':
              return MaterialPageRoute(
                builder: (_) => const InitialWalkthroughPage(),
                settings: settings,
              );
            case '/':
              return MaterialPageRoute(
                builder: (_) => NavigatorPopHandler(
                  onPopWithResult: (Object? result) =>
                      _homeNavigatorKey.currentState!.maybePop(),
                  child: Navigator(
                    initialRoute: "/",
                    key: _homeNavigatorKey,
                    onGenerateRoute: (RouteSettings settings) {
                      debugPrint("New inner route: ${settings.name}");
                      switch (settings.name) {
                        case '/':
                          return MaterialPageRoute(
                            builder: (_) => const HomePage(),
                            settings: settings,
                          );
                        case '/create-invoice':
                          return MaterialPageRoute(
                            builder: (_) => const CreateInvoicePage(),
                            settings: settings,
                          );
                      }
                      assert(false);
                      return null;
                    },
                  ),
                ),
                settings: settings,
              );
          }
          assert(false);
          return null;
        },
      );
    });
  }
}

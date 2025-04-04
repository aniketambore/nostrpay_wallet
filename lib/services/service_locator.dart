import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  AccountCubit? _accountCubit;

  void setAccountCubit(AccountCubit cubit) {
    _accountCubit = cubit;
  }

  AccountCubit? get accountCubit => _accountCubit;
}

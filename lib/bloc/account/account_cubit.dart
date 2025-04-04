import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'account_state.dart';
import 'credentials_manager.dart';

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  final CredentialsManager _credentialsManager;

  AccountCubit(
    this._credentialsManager,
  ) : super(AccountState.initial()) {
    hydrate();
  }

  @override
  AccountState? fromJson(Map<String, dynamic> json) {
    return AccountState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AccountState state) {
    return state.toJson();
  }
}

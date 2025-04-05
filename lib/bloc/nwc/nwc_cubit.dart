import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nwc_wallet/data/models/nwc_request.dart';
import 'package:nwc_wallet/nwc_wallet.dart';

import 'nwc_state.dart';

class NWCCubit extends Cubit<NWCState> with HydratedMixin {
  late final NostrKeyPair _nostrKeyPair;
  late final NwcWallet _nwcWallet;
  StreamSubscription? _requestSubscription;

  NWCCubit() : super(NWCState.initial()) {
    // Initialize storage before emitting any state
    hydrate();
  }

  Future<void> initialize(String mnemonic) async {
    try {
      debugPrint('NWCCubit: Starting initialization');
      emit(state.copyWith(isLoading: true));

      // Derive Nostr keypair from mnemonic
      _nostrKeyPair = NostrKeyPair.fromMnemonic(mnemonic);
      debugPrint(
          'NWCCubit: Derived Nostr keypair with pubkey: ${_nostrKeyPair.publicKey}');
      emit(state.copyWith(pubkey: _nostrKeyPair.publicKey));

      // Initialize NWC wallet with the keypair and existing connection if available
      if (state.connectionUri.isNotEmpty) {
        debugPrint(
            'NWCCubit: Found existing connection URI, initializing wallet with it');
        try {
          // Parse the connection URI to extract the pubkey
          debugPrint(
              'NWCCubit: Initializing wallet with connection: ${state.connectionUri}');

          // Initialize the wallet with the existing connection
          _nwcWallet = NwcWallet(
            walletNostrKeyPair: _nostrKeyPair,
            relayUrl: state.relay,
            connections: [
              NwcConnection(
                uri: state.connectionUri,
                pubkey: state.pubkey,
                permittedMethods: state.methods,
              ),
            ],
          );
        } catch (e) {
          debugPrint(
              'NWCCubit: Error initializing wallet with existing connection: $e');
          // Fall back to creating a new wallet without connections
          _nwcWallet = NwcWallet(
            walletNostrKeyPair: _nostrKeyPair,
          );
        }
      } else {
        // Initialize a new wallet without connections
        _nwcWallet = NwcWallet(
          walletNostrKeyPair: _nostrKeyPair,
        );
      }

      // Subscribe to NWC requests
      _subscribeToNwcRequests();

      emit(state.copyWith(
        isInitialized: true,
        isLoading: false,
      ));
      debugPrint('NWCCubit: Initialization completed successfully');
    } catch (e) {
      debugPrint('NWCCubit: Error initializing NWC: $e');
      final errorState = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      emit(errorState);
    }
  }

  void _subscribeToNwcRequests() {
    debugPrint('NWCCubit: Setting up NWC request subscription');
    _requestSubscription?.cancel();

    _requestSubscription = _nwcWallet.nwcRequests.listen(
      (request) {
        debugPrint('NWCCubit: Received NWC request: ${request.method}');
        _handleRequest(request);
      },
      onError: (error) {
        debugPrint('NWCCubit: Error in NWC request stream: $error');
        emit(state.copyWith(error: error.toString()));
        // Try to resubscribe on error
        _subscribeToNwcRequests();
      },
      onDone: () {
        debugPrint('NWCCubit: NWC request stream closed');
        // Try to resubscribe if the stream is closed
        _subscribeToNwcRequests();
      },
    );
    debugPrint('NWCCubit: Successfully subscribed to NWC requests');
  }

  Future<void> createConnection({String? relayUrl}) async {
    try {
      emit(state.copyWith(isLoading: true));

      debugPrint('NWCCubit: Creating new NWC connection');
      final connection = await _nwcWallet.addConnection(
        permittedMethods: state.methods,
      );
      debugPrint('NWCCubit: Created connection with URI: ${connection.uri}');

      emit(state.copyWith(
        connectionUri: connection.uri,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void _handleRequest(NwcRequest request) {
    debugPrint('NWCCubit: Handling request: ${request.method}');
    switch (request.method) {
      default:
        debugPrint('NWCCubit: Unauthorized request method: ${request.method}');
        _nwcWallet.failedToHandleRequest(
          request,
          error: NwcErrorCode.unauthorized,
        );
    }
  }

  @override
  NWCState? fromJson(Map<String, dynamic> json) {
    return NWCState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(NWCState state) {
    return state.toJson();
  }

  @override
  Future<void> close() {
    debugPrint('NWCCubit: Disposing NWC cubit');
    _requestSubscription?.cancel();
    return super.close();
  }
}

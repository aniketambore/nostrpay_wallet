import 'dart:async';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:nostrpay_wallet/services/service_locator.dart';
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
      case NwcMethod.getInfo:
        debugPrint('NWCCubit: Handling getInfo request');
        _handleGetInfoRequest(request as NwcGetInfoRequest);
        break;
      case NwcMethod.getBalance:
        debugPrint('NWCCubit: Handling getBalance request');
        _handleGetBalanceRequest(request as NwcGetBalanceRequest);
        break;
      case NwcMethod.makeInvoice:
        debugPrint('NWCCubit: Handling makeInvoice request');
        _handleMakeInvoiceRequest(request as NwcMakeInvoiceRequest);
        break;
      default:
        debugPrint('NWCCubit: Unauthorized request method: ${request.method}');
        _nwcWallet.failedToHandleRequest(
          request,
          error: NwcErrorCode.unauthorized,
        );
    }
  }

  Future<void> _handleGetInfoRequest(NwcGetInfoRequest request) async {
    try {
      debugPrint('NWCCubit: Processing getInfo request');
      await _nwcWallet.getInfoRequestHandled(
        request,
        alias: state.alias,
        color: state.color,
        pubkey: state.pubkey,
        network: state.network,
        blockHeight: state.blockHeight,
        blockHash: state.blockHash,
        methods: state.methods,
      );
      debugPrint('NWCCubit: Successfully handled getInfo request');
    } catch (e) {
      debugPrint('NWCCubit: Error handling getInfo request: $e');
      await _nwcWallet.failedToHandleRequest(
        request,
        error: NwcErrorCode.internal,
      );
    }
  }

  Future<void> _handleGetBalanceRequest(NwcGetBalanceRequest request) async {
    try {
      debugPrint('NWCCubit: Processing getBalance request');

      final accountCubit = ServiceLocator().accountCubit;
      if (accountCubit == null) {
        debugPrint('NWCCubit: Error - AccountCubit not available');
        await _nwcWallet.failedToHandleRequest(
          request,
          error: NwcErrorCode.internal,
        );
        return;
      }

      final balanceSat = await accountCubit.getSpendableBalanceSat() ?? 0;

      await _nwcWallet.getBalanceRequestHandled(
        request,
        balanceSat: balanceSat,
      );
      debugPrint(
          'NWCCubit: Successfully handled getBalance request with balance: $balanceSat sats');
    } catch (e) {
      debugPrint('NWCCubit: Error handling getBalance request: $e');
      await _nwcWallet.failedToHandleRequest(
        request,
        error: NwcErrorCode.internal,
      );
    }
  }

  Future<void> _handleMakeInvoiceRequest(NwcMakeInvoiceRequest request) async {
    try {
      debugPrint('NWCCubit: Processing makeInvoice request');

      final accountCubit = ServiceLocator().accountCubit;
      if (accountCubit == null) {
        debugPrint('NWCCubit: Error - AccountCubit not available');
        await _nwcWallet.failedToHandleRequest(
          request,
          error: NwcErrorCode.internal,
        );
        return;
      }

      // Get the amount and description from the request
      final int amountSat = request.amountSat;
      final String description = request.description ?? 'Bijli Invoice';

      // Check if we have enough inbound liquidity
      final inboundLiquiditySat = await accountCubit.getInboundLiquiditySat();

      String bolt11Invoice;

      if (inboundLiquiditySat <= amountSat) {
        // Handle LSP flow
        debugPrint('NWCCubit: Insufficient inbound liquidity, using LSP flow');

        // Get LSP fee
        final lspFeeResponse =
            await accountCubit.getLSPFee(amountSat: amountSat);
        final int lspFeeSat =
            accountCubit.mSatToSat(lspFeeResponse.feeAmountMsat);
        final int invoiceAmountSat = amountSat - lspFeeSat;

        if (invoiceAmountSat <= 0) {
          throw Exception(
              'The invoice amount must be greater than $lspFeeSat sats');
        }

        // Create the invoice
        bolt11Invoice =
            await accountCubit.addInvoice(amountSat: invoiceAmountSat);

        // Get the proposal
        final lspProposal = await accountCubit.getProposal(
          bolt11: bolt11Invoice,
          feeId: lspFeeResponse.id,
        );

        // Use the JIT bolt11 invoice
        bolt11Invoice = lspProposal.jitBolt11;
      } else {
        // Regular invoice flow
        debugPrint(
            'NWCCubit: Sufficient inbound liquidity, using regular flow');
        bolt11Invoice = await accountCubit.addInvoice(
          amountSat: amountSat,
          description: description,
        );
      }

      // Parse the bolt11 invoice to get additional details
      final paymentRequest = Bolt11PaymentRequest(bolt11Invoice);
      final String paymentHash = paymentRequest.tags
          .where((tag) => tag.type == 'payment_hash')
          .first
          .data;
      final int expiry =
          paymentRequest.tags.where((tag) => tag.type == 'expiry').first.data;
      final int amountSatFromInvoice =
          (paymentRequest.amount.toBigInt() * BigInt.from(10 ^ 8)).toInt();

      // Handle the request with the invoice details
      await _nwcWallet.makeInvoiceRequestHandled(
        request,
        invoice: bolt11Invoice,
        description: description,
        paymentHash: paymentHash,
        amountSat: amountSatFromInvoice,
        feesPaidSat: 0,
        createdAt: paymentRequest.timestamp.toInt(),
        expiresAt: expiry,
        metadata: {},
      );

      debugPrint('NWCCubit: Successfully handled makeInvoice request');
    } catch (e) {
      debugPrint('NWCCubit: Error handling makeInvoice request: $e');
      await _nwcWallet.failedToHandleRequest(
        request,
        error: NwcErrorCode.other,
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

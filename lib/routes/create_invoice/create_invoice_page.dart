import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostrpay_wallet/bloc/account/account_cubit.dart';
import 'package:nostrpay_wallet/component_library/component_library.dart';

import 'lsp_fee_confirmation_dialog.dart';
import 'qr_code_dialog.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive via Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(labelText: 'Amount in SAT'),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            _createInvoice(context);
          }
        },
        child: Text('Create'),
      ),
    );
  }

  Future<void> _createInvoice(BuildContext context) async {
    debugPrint("Creating invoice...");
    final cubit = context.read<AccountCubit>();
    final navigator = Navigator.of(context);
    navigator.push(createLoaderRoute(context));

    try {
      final int amountSat = int.parse(_amountController.text);
      final inboundLiquiditySat = await cubit.getInboundLiquiditySat();

      if (!context.mounted) return;
      if (inboundLiquiditySat <= amountSat) {
        await _handleLspFlow(context, navigator, cubit, amountSat);
      } else {
        await _handleRegularInvoiceFlow(context, navigator, cubit, amountSat);
      }
    } catch (error) {
      if (!context.mounted) return;
      navigator.pop(context);
      context.showErrorPrompt(error.toString());
    }
  }

  // Handles LSP flow when inbound liquidity is insufficient
  Future<void> _handleLspFlow(
    BuildContext context,
    NavigatorState navigator,
    AccountCubit cubit,
    int amountSat,
  ) async {
    final lspFeeResponse = await cubit.getLSPFee(amountSat: amountSat);
    final int lspFeeSat = cubit.mSatToSat(lspFeeResponse.feeAmountMsat);
    final int invoiceAmountSat = amountSat - lspFeeSat;

    if (invoiceAmountSat <= 0) {
      throw Exception(
          'The invoice amount must be greater than $lspFeeSat sats. Please enter a larger amount.');
    }

    navigator.pop();

    bool? userConfirmation =
        await _showLspFeeConfirmationDialog(context, lspFeeSat);

    if (userConfirmation == true) {
      navigator.push(createLoaderRoute(context));

      final String bolt11 = await cubit.addInvoice(amountSat: invoiceAmountSat);
      final lspProposal = await cubit.getProposal(
        bolt11: bolt11,
        feeId: lspFeeResponse.id,
      );

      debugPrint('jitBolt11: ${lspProposal.jitBolt11}');
      navigator.popUntil((route) => route.settings.name == "/");

      if (context.mounted) {
        await _showQrCodeDialog(context, lspProposal.jitBolt11);
      }
    }
  }

  // Handles regular invoice creation when inbound liquidity is sufficient
  Future<void> _handleRegularInvoiceFlow(
    BuildContext context,
    NavigatorState navigator,
    AccountCubit cubit,
    int amountSat,
  ) async {
    final String receivePaymentResponse = await cubit.addInvoice(
      amountSat: amountSat,
      description: _descriptionController.text.trim().isEmpty
          ? 'Bijli Invoice'
          : _descriptionController.text.trim(),
    );

    navigator.popUntil((route) => route.settings.name == "/");

    if (context.mounted) {
      await _showQrCodeDialog(context, receivePaymentResponse);
    }
  }

  // Shows LSP fee confirmation dialog
  Future<bool?> _showLspFeeConfirmationDialog(
      BuildContext context, int lspFeeSat) {
    return showDialog<bool>(
      context: context,
      builder: (context) => LSPFeeConfirmationDialog(feeAmountSat: lspFeeSat),
    );
  }

  Future<void> _showQrCodeDialog(
      BuildContext context, String paymentResponse) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => QrCodeDialog(
        receivePaymentResponse: paymentResponse,
        (result) {
          debugPrint("Invoice dialog closed with result: $result");
        },
      ),
    );
  }
}

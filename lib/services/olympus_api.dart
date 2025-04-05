import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nostrpay_wallet/app_config.dart';
import 'package:nostrpay_wallet/models/models.dart';

/// Docs: https://docs.zeusln.app/lsp/services/flow/

class OlympusApi {
  OlympusApi()
      : _dio = Dio(),
        _urlBuilder = UrlBuilder() {
    _dio.interceptors.add(
      LogInterceptor(responseBody: false),
    );
  }

  final Dio _dio;
  final UrlBuilder _urlBuilder;

  Future<OlympusFeeResponseRM> getLSPFee({
    required int amountMSat,
    required String pubkey,
  }) async {
    debugPrint("[+] Getting LSP Fee");
    final url = _urlBuilder.buildFeeUrl();
    final requestJsonBody =
        OlympusFeeRequestRM(amountMSat: amountMSat, pubkey: pubkey).toJson();

    try {
      final response = await _dio.post(url, data: requestJsonBody);
      final jsonObject = response.data;
      final res = OlympusFeeResponseRM.fromJson(jsonObject);
      return res;
    } on DioException catch (e) {
      debugPrint("[!] Error getting LSP fee: ${e.message}");
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection timeout while getting LSP fee");
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception("Connection error while getting LSP fee");
      } else {
        throw Exception("Failed to get LSP fee: ${e.message}");
      }
    } catch (e) {
      debugPrint("[!] Unexpected error getting LSP fee: $e");
      throw Exception("Unexpected error while getting LSP fee: $e");
    }
  }

  Future<OlympusProposalResponseRM> getProposal({
    required String bolt11,
    required String feeId,
  }) async {
    debugPrint("[+] Getting LSP Proposal");
    final url = _urlBuilder.buildProposalUrl();
    final requestJsonBody =
        OlympusProposalRequestRM(bolt11: bolt11, feeId: feeId).toJson();

    try {
      final response = await _dio.post(url, data: requestJsonBody);
      final jsonObject = response.data;
      final res = OlympusProposalResponseRM.fromJson(jsonObject);
      return res;
    } on DioException catch (e) {
      debugPrint("[!] Error getting LSP proposal: ${e.message}");
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection timeout while getting LSP proposal");
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception("Connection error while getting LSP proposal");
      } else {
        throw Exception("Failed to get LSP proposal: ${e.message}");
      }
    } catch (e) {
      debugPrint("[!] Unexpected error getting LSP proposal: $e");
      throw Exception("Unexpected error while getting LSP proposal: $e");
    }
  }
}

class UrlBuilder {
  UrlBuilder({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConfig.olympusLspUrl.signet;

  final String _baseUrl;

  String buildFeeUrl() {
    return '$_baseUrl/api/v1/fee';
  }

  String buildProposalUrl() {
    return '$_baseUrl/api/v1/proposal';
  }
}

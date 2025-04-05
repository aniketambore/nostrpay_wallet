import 'package:json_annotation/json_annotation.dart';

part 'olympus_fee_response_rm.g.dart';

@JsonSerializable(createToJson: false)
class OlympusFeeResponseRM {
  const OlympusFeeResponseRM({
    required this.feeAmountMsat,
    required this.id,
  });

  @JsonKey(name: 'fee_amount_msat')
  final int feeAmountMsat;
  final String id;

  static const fromJson = _$OlympusFeeResponseRMFromJson;
}

import 'package:json_annotation/json_annotation.dart';

part 'olympus_fee_request_rm.g.dart';

@JsonSerializable(createFactory: false)
class OlympusFeeRequestRM {
  const OlympusFeeRequestRM({
    required this.amountMSat,
    required this.pubkey,
  });

  @JsonKey(name: 'amount_msat')
  final int amountMSat;
  final String pubkey;

  Map<String, dynamic> toJson() => _$OlympusFeeRequestRMToJson(this);
}
